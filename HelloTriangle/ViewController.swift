//
//  ViewController.swift
//  HelloTriangle
//
//  Created by Александр Янчик on 11.05.23.
//

import UIKit
import Metal
import QuartzCore

class ViewController: UIViewController {

    private var device: MTLDevice?
    private var metalLayer: CAMetalLayer?
    private var vertexBuffer: MTLBuffer?
    private var pipelineState: MTLRenderPipelineState?
    private var commandQueue: MTLCommandQueue?
    
    let vertexData: [Float] = [
        0.0, 0.5, 0.0,
        -0.5, -0.5, 0.0,
        0.5, -0.5, 0.0,
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupController()
        self.setupVertexBuffer()
        self.setupShaders()
        self.setupCommandQueue()
        self.setupDisplayLink()
    }

    private func setupController() {
        device = MTLCreateSystemDefaultDevice()
        
        metalLayer = CAMetalLayer()
        metalLayer?.device = device
        metalLayer?.pixelFormat = .bgra8Unorm
        metalLayer?.framebufferOnly = true
        metalLayer?.frame = view.layer.frame
        
        guard let metalLayer else { return }
        
        view.layer.addSublayer(metalLayer)
        
    }
    
    private func setupVertexBuffer() {
        guard let device else { return }
        let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: [])
    }
    
    private func setupShaders() {
        guard let device,
              let defaultLibrary = device.makeDefaultLibrary()
        else { return }
        
        let fragmentProgram = defaultLibrary.makeFunction(name: "basic_fragment")
        let vertexProgram = defaultLibrary.makeFunction(name: "basic_vertex")
            
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            
        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    }
    
    private func setupCommandQueue() {
        guard let device else { return }
        
        commandQueue = device.makeCommandQueue()
    }
    
    private func setupDisplayLink() {
        let timer = CADisplayLink(target: self, selector: #selector(gameLoop))
        timer.add(to: RunLoop.main, forMode: .default)
    }
    
    private func render() {
        guard let drawable = metalLayer?.nextDrawable(),
              let pipelineState
        else { return }
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(
            red: 0.0,
            green: 104.0/255.0,
            blue: 55.0/255.0,
            alpha: 1.0
        )
        
        let commandBuffer = commandQueue?.makeCommandBuffer()
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderEncoder?.setRenderPipelineState(pipelineState)
        renderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1)
        renderEncoder?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
    
    @objc private func gameLoop() {
        autoreleasepool {
            self.render()
        }
    }
    
}

