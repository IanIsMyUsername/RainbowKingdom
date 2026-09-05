//
//  StableDiffusionEngine.swift
//  RainbowKingdom
//
//  对 Apple ml-stable-diffusion 的 StableDiffusionPipeline 做一层异步封装：
//  模型加载和出图都是重计算，放在专用串行队列上跑，同一时间只生成一张。
//

import CoreGraphics
import CoreML
import Foundation
import StableDiffusion

final class StableDiffusionEngine: @unchecked Sendable {
    struct Request {
        var prompt: String
        var negativePrompt: String = ""
        var stepCount: Int = 20
        var guidanceScale: Float = 7.5
        var seed: UInt32 = .random(in: 0...UInt32.max)
    }

    private let queue = DispatchQueue(label: "com.chunxiao.RainbowKingdom.stable-diffusion", qos: .userInitiated)
    private var pipeline: StableDiffusionPipeline?

    var isLoaded: Bool { queue.sync { pipeline != nil } }

    /// 加载并预编译模型。首次运行需要编译 Core ML 模型，约 30 到 60 秒；之后系统有缓存，几秒即可。
    func load(resourcesAt url: URL) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async {
                if self.pipeline != nil {
                    continuation.resume()
                    return
                }
                do {
                    let config = MLModelConfiguration()
                    // split_einsum 模型为神经引擎优化；CPU+ANE 组合内存最省、在 iPad 上最稳
                    config.computeUnits = .cpuAndNeuralEngine
                    let pipeline = try StableDiffusionPipeline(
                        resourcesAt: url,
                        controlNet: [],
                        configuration: config,
                        disableSafety: true,
                        reduceMemory: false
                    )
                    try pipeline.loadResources()
                    self.pipeline = pipeline
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func unload() {
        queue.async {
            self.pipeline?.unloadResources()
            self.pipeline = nil
        }
    }

    /// 生成一张 512x512 图。progress 回调在后台线程，参数为 0...1。
    func generate(_ request: Request, progress: (@Sendable (Double) -> Void)? = nil) async throws -> CGImage? {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CGImage?, Error>) in
            queue.async {
                guard let pipeline = self.pipeline else {
                    continuation.resume(throwing: EngineError.notLoaded)
                    return
                }
                var config = StableDiffusionPipeline.Configuration(prompt: request.prompt)
                config.negativePrompt = request.negativePrompt
                config.stepCount = request.stepCount
                config.guidanceScale = request.guidanceScale
                config.seed = request.seed
                config.imageCount = 1
                config.disableSafety = true
                config.schedulerType = .dpmSolverMultistepScheduler

                do {
                    let images = try pipeline.generateImages(configuration: config) { step in
                        // step 从 0 开始计数，+1 后最后一步正好 100%；之后还有 VAE 解码约一两秒
                        progress?(Double(step.step + 1) / Double(max(step.stepCount, 1)))
                        return true
                    }
                    continuation.resume(returning: images.first ?? nil)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    enum EngineError: LocalizedError {
        case notLoaded
        var errorDescription: String? { "模型尚未加载" }
    }
}
