module david.input.sdl;

import derelict.sdl2.sdl :
    SDL_Scancode,
    SDL_KeyboardEvent;

alias InputCodeBaseType = typeof(SDL_KeyboardEvent.keysym.scancode);
enum InputCode : InputCodeBaseType
{
    a = SDL_Scancode.SDL_SCANCODE_A,
    d = SDL_Scancode.SDL_SCANCODE_D,
    f = SDL_Scancode.SDL_SCANCODE_F,
    s = SDL_Scancode.SDL_SCANCODE_S,
    w = SDL_Scancode.SDL_SCANCODE_W,
    left = SDL_Scancode.SDL_SCANCODE_LEFT,
    right = SDL_Scancode.SDL_SCANCODE_RIGHT,
    escape = SDL_Scancode.SDL_SCANCODE_ESCAPE,
}
