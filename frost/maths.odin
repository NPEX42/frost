package frost

import "core:math/linalg"
mat4f :: distinct matrix[4, 4]f32


Mat4f_Ortho :: proc(left, right, top, bottom, near, far: f32) -> mat4f {
    m := linalg.identity(mat4f)

    m[0][0] =  2.0 / right - left
    m[1][1] =  2.0 / top - bottom
    m[2][2] = -2.0 / far - near

    m[3][0] = -((right + left) / (right - left))
    m[3][1] = -((top + bottom) / (top - bottom))
    m[3][2] = -((far + near) / (far - near))

    m[3][3] = 1
 
    return m
}