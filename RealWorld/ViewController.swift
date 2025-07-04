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
    
    // MARK: - Helper Methods
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

