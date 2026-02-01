import SwiftSDL
import Libbit
import UIKit

@main
final class FrogRaceGame: Game {
    private enum CodingKeys: String, CodingKey {
      case options, message
    }

    @OptionGroup
    var options: GameOptions

    @Argument
    var message: String = "Hello, SwiftSDL!"
    
    var state: GameState = start_game()

    private var renderer: (any Renderer)! = nil
    
    var textureCache: [String: UnsafeMutablePointer<SDL_Texture>] = [:]

    func onReady(window: any Window) throws(SDL_Error) {
        renderer = try window.createRenderer()
            message = state.get_state().toString()
        
        if let tex = makeTextureFromAsset(
            named: "frogsprite",
            sdlRenderer: renderer.pointer
        ) {
            textureCache["frogsprite"] = tex
        } else {
            print("Failed to load frogsprite texture")
        }
    }

    func onUpdate(window: any Window) throws(SDL_Error) {
        try renderer
            .clear(color: .gray)
            .debug(text: message, position: [12, 12], scale: [2, 2])
        draw_entitites()
        try renderer.present()
    }

    func onEvent(window: any Window, _ event: SDL_Event) throws(SDL_Error) {
        handle_input(event: event)
        message = state.get_state().toString()
    }
    
    func draw_entitites() {
        let entities = state.get_entities()

        for entity in entities {
            let key: String
            switch entity.kind() {
            case Libbit.EntityKind.Racer:
                key = "frogsprite"
            default:
                key = "frogsprite"
            }

            guard let texture = textureCache[key] else { continue }

            var dst = SDL_FRect(x: 100, y: 100, w: 64, h: 64)
            SDL_RenderTexture(renderer.pointer, texture, nil, &dst)
        }
    }
    
    func handle_input(event: SDL_Event) {
        switch event.eventType {
            case SDL_EVENT_FINGER_DOWN:
                state.tick(Input.Activate)
            case _:
                ()
        }
    }

    func onShutdown(window: (any Window)?) throws(SDL_Error) {
      renderer = nil
        for (_, tex) in textureCache {
            SDL_DestroyTexture(tex)
        }
        textureCache.removeAll()
    }
}

func makeTextureFromAsset(
    named assetName: String,
    sdlRenderer: OpaquePointer
) -> UnsafeMutablePointer<SDL_Texture>? {

    guard let uiImage = UIImage(named: assetName),
          let cgImage = uiImage.cgImage else {
        print("Asset '\(assetName)' not found")
        return nil
    }

    let w = cgImage.width
    let h = cgImage.height
    let pitch = w * 4
    let byteCount = h * pitch

    let pixels = UnsafeMutableRawPointer.allocate(byteCount: byteCount, alignment: 64)
    pixels.initializeMemory(as: UInt8.self, repeating: 0, count: byteCount)

    let colorSpace = cgImage.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!

    guard let ctx = CGContext(
        data: pixels,
        width: w,
        height: h,
        bitsPerComponent: 8,
        bytesPerRow: pitch,
        space: colorSpace,
        bitmapInfo:
            CGImageAlphaInfo.premultipliedLast.rawValue |
            CGBitmapInfo.byteOrder32Big.rawValue
    ) else {
        pixels.deallocate()
        return nil
    }


    ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))

    let format: SDL_PixelFormat = SDL_PIXELFORMAT_RGBA32

    guard let surface = SDL_CreateSurfaceFrom(
        Int32(w),
        Int32(h),
        format,
        pixels,
        Int32(pitch)
    ) else {
        print("SDL_CreateSurfaceFrom failed: \(String(cString: SDL_GetError()))")
        pixels.deallocate()
        return nil
    }

    guard let tex = SDL_CreateTextureFromSurface(sdlRenderer, surface) else {
        print("SDL_CreateTextureFromSurface failed: \(String(cString: SDL_GetError()))")
        SDL_DestroySurface(surface)
        pixels.deallocate()
        return nil
    }

    SDL_DestroySurface(surface)
    pixels.deallocate()
    return tex
}
