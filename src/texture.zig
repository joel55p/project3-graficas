const std = @import("std");
const rl = @import("raylib");

//esto genera las texturas que usan los planets, ademas que tambien es reusado del raytracer q igual  sin imagenes externas

pub const Textura = struct { //array 2D colores
    ancho: usize,
    alto: usize,
    pixeles: []rl.Color,

    pub fn muestrear(self: Textura, u_raw: f32, v_raw: f32) rl.Vector3 { //segun punto en coor [0,1], devuelve el color que le toca
        var u = u_raw - @floor(u_raw);
        var v = v_raw - @floor(v_raw);
        if (u < 0) u += 1;
        if (v < 0) v += 1;

        //si se pasa de 1 entonces se repite la textura
        const w_f: f32 = @floatFromInt(self.ancho);
        const h_f: f32 = @floatFromInt(self.alto);
        const x: usize = @intFromFloat(@min(w_f - 1, u * w_f));
        const y: usize = @intFromFloat(@min(h_f - 1, v * h_f));

        const pixel = self.pixeles[y * self.ancho + x];
        const r: f32 = @floatFromInt(pixel.r);
        const g: f32 = @floatFromInt(pixel.g);
        const b: f32 = @floatFromInt(pixel.b);
        return .{ .x = r / 255.0, .y = g / 255.0, .z = b / 255.0 };
    }
};

//convierte Vector3 0,1 a rl.Color pa pintar en framebuffer
pub fn V3ToColor(color: rl.Vector3) rl.Color {
    const r: u8 = @intFromFloat(@max(0, @min(255, color.x * 255)));
    const g: u8 = @intFromFloat(@max(0, @min(255, color.y * 255)));
    const b: u8 = @intFromFloat(@max(0, @min(255, color.z * 255)));
    return .{ .r = r, .g = g, .b = b, .a = 0xff };
}

//generadores tambien de raytracer 

pub fn crear_tablero(alloc: std.mem.Allocator, tam: usize, celda: usize, c1: rl.Color, c2: rl.Color) !Textura { //aqui se vaa ir turnando colores de cuadros
    const pixeles = try alloc.alloc(rl.Color, tam * tam);
    for (0..tam) |y| {
        for (0..tam) |x| {
            const cuadro = ((x / celda) + (y / celda)) % 2 == 0;
            pixeles[y * tam + x] = if (cuadro) c1 else c2;
        }
    }
    return .{ .ancho = tam, .alto = tam, .pixeles = pixeles };
}

//lineas horizontales para planetas gaseosos o igual el  sol
pub fn crear_franjas(alloc: std.mem.Allocator, tam: usize, grosor: usize, c1: rl.Color, c2: rl.Color) !Textura {
    const pixeles = try alloc.alloc(rl.Color, tam * tam);
    for (0..tam) |y| {
        for (0..tam) |x| {
            const franja = (y / grosor) % 2 == 0;
            pixeles[y * tam + x] = if (franja) c1 else c2;
        }
    }
    return .{ .ancho = tam, .alto = tam, .pixeles = pixeles };
}

//textura de un solo color
pub fn crear_solido(alloc: std.mem.Allocator, tam: usize, color: rl.Color) !Textura {
    const pixeles = try alloc.alloc(rl.Color, tam * tam);
    @memset(pixeles, color);
    return .{ .ancho = tam, .alto = tam, .pixeles = pixeles };
}

//patron de ladrillos con lineas de junta, como para los planetas asi de rocas
pub fn crear_ladrillos(alloc: std.mem.Allocator, tam: usize, c_ladrillo: rl.Color, c_junta: rl.Color) !Textura { 
    const pixeles = try alloc.alloc(rl.Color, tam * tam);
    const alto_ladrillo: usize = tam / 4;
    const ancho_ladrillo: usize = tam / 4;
    const grosor_junta: usize = 1;

    //filas impares estan movidas mdio ladrillo para que no se alineen
    for (0..tam) |y| {
        for (0..tam) |x| {
            const fila = y / alto_ladrillo;
            const x_offset = if (fila % 2 == 0) x else x + ancho_ladrillo / 2;
            const es_junta_h = (y % alto_ladrillo) < grosor_junta;
            const es_junta_v = (x_offset % ancho_ladrillo) < grosor_junta;

            pixeles[y * tam + x] = if (es_junta_h or es_junta_v) c_junta else c_ladrillo;
        }
    }
    return .{ .ancho = tam, .alto = tam, .pixeles = pixeles };
}
