import SwiftSDL
import Libbit

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

    func onReady(window: any Window) throws(SDL_Error) {
      renderer = try window.createRenderer()
        message = state.get_state().toString()
    }

    func onUpdate(window: any Window) throws(SDL_Error) {
        draw_entitites()
      try renderer
        .clear(color: .gray)
        .debug(text: message, position: [12, 12], scale: [2, 2])
        
        .present()
    }

    func onEvent(window: any Window, _ event: SDL_Event) throws(SDL_Error) {
        handle_input(event: event)
        message = state.get_state().toString()
    }
    
    func draw_entitites() {
        let entities = state.get_entities()
        for entity in entities {
            debugPrint(entity.kind())
            debugPrint(entity.x())
            debugPrint(entity.y())
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
    }
}
