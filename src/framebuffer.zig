const std = @import("std");
const rl = @import("raylib");

//buffer de pixeles en memoria que se uso para los triangulos
pub const Framebuffer = struct {
    ancho: usize,
    alto: usize,
    imagen: rl.Image,
    zbuffer: []f32,
    textura_gpu: ?rl.Texture = null,

    pub fn init(alloc: std.mem.Allocator, w: usize, h: usize) !Framebuffer { //se crea imagen negra de w x h
        const zb = try alloc.alloc(f32, w * h);
        @memset(zb, std.math.floatMax(f32));
        return .{
            .ancho = w,
            .alto = h,
            .imagen = rl.genImageColor(@intCast(w), @intCast(h), .black),
            .zbuffer = zb,
        };
    }

    //va a devolver puntero directo al array de colores
    pub fn obtener_pixeles(self: *Framebuffer) [*]rl.Color {
        return @ptrCast(@alignCast(self.imagen.data)); //asi porque rl.Image.data es puntero a void, y se necesita puntero a Color
    }

    pub fn limpiar(self: *Framebuffer) void { //pone todo en black y reinicia el zbuffer
        self.imagen.clearBackground(.black);
        @memset(self.zbuffer, std.math.floatMax(f32));
    }

    //pinta un pixel directo si cae adentro de ventana
    pub fn poner_pixel(self: *Framebuffer, x: i32, y: i32, color: rl.Color) void {
        if (x < 0 or y < 0) return;
        const ux: usize = @intCast(x);
        const uy: usize = @intCast(y);
        if (ux >= self.ancho or uy >= self.alto) return;
        const pixeles = self.obtener_pixeles();
        pixeles[uy * self.ancho + ux] = color;
    }

    pub fn mostrar(self: *Framebuffer) !void { //sube imagen al GPU como textura y  despues dibuja en pantalla
        rl.beginDrawing();
        defer rl.endDrawing();

        if (self.textura_gpu) |t| rl.unloadTexture(t);

        const tex = try rl.loadTextureFromImage(self.imagen);
        rl.drawTexture(tex, 0, 0, .white);
        self.textura_gpu = tex;
    }

    pub fn liberar(self: *Framebuffer, alloc: std.mem.Allocator) void {
        if (self.textura_gpu) |t| rl.unloadTexture(t);
        rl.unloadImage(self.imagen);
        alloc.free(self.zbuffer);
    }
};
