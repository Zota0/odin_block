package files

import "core:os"
import "core:fmt"

ReadFile :: proc(path: string) -> string {
    data, err := os.read_entire_file(path)
    if err {
        fmt.println("Failed to read file!")
        return ""
    }
    return string(data)
}