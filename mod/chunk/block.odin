package chunk

import fmt "core:fmt"
import "core:strings"

BLOCK_TYPE :: enum {
    EMPTY = 0,
    SOLID = 1,
    LIQUID = 2,
    MODIFIER = 3,
}

BLOCK_ID :: enum {
    AIR = 0,
    DIRT = 1,
}

BLOCK_NAME := []string{
    "air",
    "dirt",
}


Block :: struct {
    x : i8,
    y : i8,
    z : i8,
    chunkID: i32,
    block_type : BLOCK_TYPE,
    id : BLOCK_ID,
}

GetBlockTex :: proc(block: Block) -> string {
    return fmt.tprintf("assets/%v.png", BLOCK_NAME[block.id])
}

SomeBlock : Block = {
    0, 0, 0,
    0, BLOCK_TYPE.SOLID, BLOCK_ID.DIRT,
}