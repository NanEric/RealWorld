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
    var scaleSlider: UISlider!
    
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
        
        // 添加缩放滑块
        setupScaleSlider()
        
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
            
            // 打印所有子节点的名称和详细信息
            print("Child nodes:")
            for node in modelScene.rootNode.childNodes {
                print("Node name: \(node.name ?? "No name")")
                print("Node position: \(node.position)")
                print("Node scale: \(node.scale)")
                print("Node rotation: \(node.rotation)")
                if let geometry = node.geometry {
                    print("Node has geometry")
                    print("Geometry bounds: \(geometry.boundingBox)")
                    print("Geometry elements: \(geometry.elements.count)")
                } else {
                    print("Node has no geometry")
                }
            }
            
            // 尝试找到第一个可显示的节点
            var modelNode: SCNNode?
            
            // 首先尝试使用根节点
            if modelScene.rootNode.childNodes.count > 0 {
                modelNode = modelScene.rootNode
                print("Using root node with all children")
            } else {
                print("Root node has no children")
                return
            }
            
            // 如果找到合适的节点
            if let model = modelNode {
                // 设置模型位置
                model.position = SCNVector3(
                    position.x,
                    position.y + 0.1, // 略微抬高模型
                    position.z - 1.0 // 向后移动1.0米
                )
                
                print("Model position before adjustment: x=\(model.position.x), y=\(model.position.y), z=\(model.position.z)")
                
                // 设置模型缩放（如果模型太大或太小，可以调整这个值）
                model.scale = SCNVector3(0.05, 0.05, 0.05) // 减小初始缩放值
                
                // 添加到场景中
                sceneView.scene.rootNode.addChildNode(model)
                self.modelNode = model
                
                // 打印模型状态信息
                print("Model loaded successfully!")
                print("Model position: \(model.position)")
                print("Model scale: \(model.scale)")
                print("Model bounds: \(model.boundingBox)")
                
                // 检查模型的所有属性
                print("Model node properties:")
                print("Has geometry: \(model.geometry != nil)")
                print("Has materials: \(model.geometry?.materials.count ?? 0)")
                
                // 如果模型不可见，尝试添加一个简单的几何体作为测试
                if let geometry = model.geometry {
                    if !geometry.elements.isEmpty {
                        print("Model has geometry with \(geometry.elements.count) elements")
                    } else {
                        print("Model has geometry but no elements!")
                    }
                } else {
                    print("Model has no geometry!")
                    
                    // 如果没有几何体，添加一个测试的立方体
                    let box = SCNBox(width: 0.05, height: 0.05, length: 0.05, chamferRadius: 0) // 也调整测试立方体的大小
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
        // 如果已经有模型节点，不再加载新的模型
        guard modelNode == nil else { return }
        
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // 打印平面锚点信息
        print("Plane anchor center: x=\(planeAnchor.center.x), y=\(planeAnchor.center.y), z=\(planeAnchor.center.z)")
        print("Plane anchor extent: x=\(planeAnchor.extent.x), z=\(planeAnchor.extent.z)")
        
        // 创建一个平面几何体
        let planeGeometry = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        
        // 设置平面材质为半透明红色
        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents = UIColor.red.withAlphaComponent(0.5)
        planeGeometry.materials = [planeMaterial]
        
        // 创建平面节点
        let planeNode = SCNNode(geometry: planeGeometry)
        
        // 设置平面位置
        planeNode.position = SCNVector3(
            Float(planeAnchor.center.x),
            Float(planeAnchor.center.y) + Float(planeGeometry.height * 0.5), // 平面中心对齐
            Float(planeAnchor.center.z)
        )
        
        // 设置平面朝向
        planeNode.rotation = SCNVector4(1, 0, 0, -Float.pi / 2)
        
        // 将平面添加到场景中
        sceneView.scene.rootNode.addChildNode(planeNode)
        
        // 在检测到的平面上放置模型
        let position = SCNVector3(
            planeAnchor.center.x,
            planeAnchor.center.y + 0.05, // 略微抬高模型
            planeAnchor.center.z
        )
        
        // 不要向后移动，保持在检测到的平面上
        print("Model position: x=\(position.x), y=\(position.y), z=\(position.z)")
        
        loadModel(at: position)
    }
    
    // MARK: - Scale Slider Setup
    private func setupScaleSlider() {
        // 创建缩放滑块
        scaleSlider = UISlider()
        scaleSlider.minimumValue = 0.01
        scaleSlider.maximumValue = 1.0
        scaleSlider.value = 0.1 // 默认值
        scaleSlider.addTarget(self, action: #selector(scaleSliderValueChanged), for: .valueChanged)
        
        // 设置滑块样式
        scaleSlider.minimumTrackTintColor = .systemBlue
        scaleSlider.maximumTrackTintColor = .systemGray
        scaleSlider.thumbTintColor = .systemBlue
        
        // 添加到视图
        view.addSubview(scaleSlider)
        
        // 添加约束
        scaleSlider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scaleSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scaleSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scaleSlider.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    @objc private func scaleSliderValueChanged(_ sender: UISlider) {
        // 更新模型缩放
        guard let modelNode = modelNode else { return }
        
        let scaleValue = Float(sender.value)
        modelNode.scale = SCNVector3(scaleValue, scaleValue, scaleValue)
        
        // 打印缩放信息
        print("Model scale set to: \(scaleValue)")
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

