//
//  ViewController.swift
//  RealWorld
//
//  Created by eric on 2025/7/3.
//

import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    // MARK: - Properties
    var sceneView: ARSCNView!
    var modelNode: SCNNode?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupARView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startARSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    // MARK: - AR Setup
    private func setupARView() {
        // 初始化ARSCNView
        sceneView = ARSCNView(frame: view.bounds)
        view.addSubview(sceneView)
        
        // 设置代理
        sceneView.delegate = self
        
        // 显示统计数据（fps等）
        sceneView.showsStatistics = true
        
        // 启用默认光照
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        
        // 添加约束
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sceneView.topAnchor.constraint(equalTo: view.topAnchor),
            sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Model Loading
    private func loadModel(at position: SCNVector3) {
        // 打印模型文件路径
        print("Looking for model at: macbook-pro-m4-pro-14in-space-black-ios18-A244173830641281.usdz")
        
        // 尝试获取模型文件URL
        guard let url = Bundle.main.url(forResource: "macbook-pro-m4-pro-14in-space-black-ios18-A244173830641281", withExtension: "usdz") else {
            let message = "无法找到模型文件。请确保文件已正确添加到项目中，并且名称正确。"
            print("Error: " + message)
            showAlert(title: "加载失败", message: message)
            return
        }
        
        // 打印找到的文件路径
        print("Found model at: \(url.path)")
        
        do {
            // 尝试加载模型
            let modelScene = try SCNScene(url: url)
            
            // 打印场景的根节点信息
            print("Root node name: \(modelScene.rootNode.name ?? "No name")")
            print("Number of child nodes: \(modelScene.rootNode.childNodes.count)")
            
            // 尝试找到第一个可显示的节点
            var modelNode: SCNNode?
            
            // 首先尝试使用"Scene"作为根节点
            if let sceneNode = modelScene.rootNode.childNode(withName: "Scene", recursively: true) {
                modelNode = sceneNode
                print("Found Scene node")
            } else {
                // 如果找不到Scene节点，尝试使用根节点的第一个子节点
                if modelScene.rootNode.childNodes.count > 0 {
                    modelNode = modelScene.rootNode.childNodes[0]
                    print("Using first child node as model node")
                } else {
                    // 如果根节点没有子节点，直接使用根节点
                    modelNode = modelScene.rootNode
                    print("Using root node as model node")
                }
            }
            
            // 如果找到合适的节点
            if let model = modelNode {
                // 设置模型位置
                model.position = position
                
                // 设置模型缩放（如果模型太大或太小，可以调整这个值）
                model.scale = SCNVector3(0.1, 0.1, 0.1)
                
                // 添加到场景中
                sceneView.scene.rootNode.addChildNode(model)
                self.modelNode = model
                
                // 打印模型状态信息
                print("Model loaded successfully!")
                print("Model position: \(model.position)")
                print("Model scale: \(model.scale)")
                print("Model bounds: \(model.boundingBox)")
                
                // 检查模型是否有几何体
                if let geometry = model.geometry {
                    if !geometry.elements.isEmpty {
                        print("Model has geometry with \(geometry.elements.count) elements")
                    } else {
                        print("Model has geometry but no elements!")
                    }
                } else {
                    print("Model has no geometry!")
                    
                    // 如果没有几何体，添加一个测试的立方体
                    let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
                    model.geometry = box
                    model.geometry?.firstMaterial?.diffuse.contents = UIColor.red
                    print("Added test box geometry")
                }
            } else {
                let message = "无法找到合适的模型节点。请检查USDZ文件的内部结构。"
                print("Error: " + message)
                showAlert(title: "加载失败", message: message)
            }
            
        } catch {
            // 捕获并显示加载错误
            print("Error loading model: \(error.localizedDescription)")
            showAlert(title: "加载失败", message: "模型加载错误: \(error.localizedDescription)")
        }
    }
    
    private func startARSession() {
        // 检查设备是否支持AR
        guard ARWorldTrackingConfiguration.isSupported else {
            showAlert(title: "不支持AR", message: "您的设备不支持AR功能")
            return
        }
        
        // 创建会话配置
        let configuration = ARWorldTrackingConfiguration()
        
        // 启用平面检测（水平面）
        configuration.planeDetection = [.horizontal]
        
        // 运行视图会话
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // 在检测到的平面上放置模型
        let position = SCNVector3(
            planeAnchor.center.x,
            planeAnchor.center.y + 0.05, // 略微抬高模型
            planeAnchor.center.z
        )
        
        loadModel(at: position)
    }
    
    // MARK: - Helper Methods
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            self?.present(alert, animated: true)
        }
        
    }
}

