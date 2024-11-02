package lua_loader
import "base:runtime"
import "core:c"
import "core:fmt"
import "core:os"
import lua "vendor:lua/5.4"

// State manager structure
LuaVM :: struct {
    state: ^lua.State,
    ctx: runtime.Context,
}

// Error type
LuaError :: enum {
    None,
    Load_Failed,
    Execution_Failed,
    Invalid_State,
}

// Initialize Lua VM
new_lua_vm :: proc() -> (vm: ^LuaVM, err: LuaError) {
    vm = new(LuaVM)
    vm.ctx = context
    vm.state = lua.newstate(LuaAlloc, &vm.ctx)
    if vm.state == nil {
        free(vm)
        return nil, .Invalid_State
    }
    lua.L_openlibs(vm.state)
    return vm, .None
}

// Memory allocator
LuaAlloc :: proc "cdecl" (ud: rawptr, ptr: rawptr, osize, nsize: uint) -> (buf: rawptr) {
    ctx := (^runtime.Context)(ud)^
    context = ctx
    if ptr == nil {
        data, err := runtime.mem_alloc(int(nsize))
        return raw_data(data) if err == .None else nil
    } else {
        if nsize > 0 {
            data, err := runtime.mem_resize(ptr, int(osize), int(nsize))
            return raw_data(data) if err == .None else nil
        } else {
            runtime.mem_free(ptr)
            return nil
        }
    }
}

// Load Lua file
load_lua_file :: proc(vm: ^LuaVM, filename: string) -> LuaError {
    if vm == nil || vm.state == nil do return .Invalid_State
    
    data, ok := os.read_entire_file(filename)
    if !ok do return .Load_Failed
    defer delete(data)
    
    status := lua.L_loadbuffer(vm.state, ([^]u8)(raw_data(data)), len(data), cstring(raw_data(filename)))
    if status != lua.OK do return .Load_Failed
    
    if lua.pcall(vm.state, 0, 0, 0) != 0 do return .Execution_Failed
    return .None
}

// Example Odin function to be called from Lua
add_numbers :: proc "c" (L: ^lua.State) -> c.int {
    a := lua.tonumber(L, 1)
    b := lua.tonumber(L, 2)
    lua.pushnumber(L, a + b)
    return 1
}

get_player_name :: proc "c" (L: ^lua.State) -> c.int {
    lua.pushstring(L, "Hero")
    return 1
}

set_game_score :: proc "c" (L: ^lua.State) -> c.int {
    context = runtime.default_context()
    score := lua.tointeger(L, 1)
    fmt.printf("Game score set to: %v\n", score)
    return 0
}

// Binding helper
LuaBinding :: struct {
    name: cstring,
    fn: lua.CFunction,
}

// Register Odin functions to Lua
register_functions :: proc(vm: ^LuaVM, bindings: []LuaBinding) -> LuaError {
    if vm == nil || vm.state == nil do return .Invalid_State
    
    for binding in bindings {
        lua.pushcclosure(vm.state, binding.fn, 0)
        lua.setglobal(vm.state, binding.name)
    }
    return .None
}

// Register a global variable in Lua
register_number :: proc(vm: ^LuaVM, name: cstring, value: lua.Number) -> LuaError {
    if vm == nil || vm.state == nil do return .Invalid_State
    lua.pushnumber(vm.state, value)
    lua.setglobal(vm.state, name)
    return .None
}

register_string :: proc(vm: ^LuaVM, name: cstring, value: string) -> LuaError {
    if vm == nil || vm.state == nil do return .Invalid_State
    lua.pushstring(vm.state, cstring(raw_data(value)))
    lua.setglobal(vm.state, name)
    return .None
}

// Clean up
destroy_lua_vm :: proc(vm: ^LuaVM) {
    if vm != nil {
        if vm.state != nil {
            lua.close(vm.state)
        }
        free(vm)
    }
}

// Example usage
main :: proc() {
    // Create new Lua VM
    vm, err := new_lua_vm()
    if err != .None {
        fmt.println("Failed to create Lua VM")
        return
    }
    defer destroy_lua_vm(vm)
    
    // Register Odin functions
    bindings := []LuaBinding{
        {"add_numbers", add_numbers},
        {"get_player_name", get_player_name},
        {"set_game_score", set_game_score},
    }
    register_functions(vm, bindings)
    
    // Register some global variables
    register_number(vm, "MAX_HEALTH", 100)
    register_string(vm, "GAME_VERSION", "1.0.0")
    
    // Load and execute Lua script
    if err := load_lua_file(vm, "game_logic.lua"); err != .None {
        fmt.println("Failed to load Lua file:", err)
        return
    }
}