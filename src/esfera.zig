const std = @import("std");
const rl = @import("raylib");

pub const Vertice = struct {
    pos: rl.Vector3,
    uv: [2]f32,
};

pub const Cara = [3]usize; //triangulo que guarda sus 3 indices

//red de triangulos para dibujar las esferas de los planeta
pub const EsferaMalla = struct {
    vertices: std.ArrayList(Vertice),
    caras: std.ArrayList(Cara),

    pub fn crear(alloc: std.mem.Allocator, divisiones: usize) !EsferaMalla { //hace esfera como cuadricula 
        var vertices: std.ArrayList(Vertice) = .empty;
        //sobre latitud y longitud
        var caras: std.ArrayList(Cara) = .empty;
        

        for (0..divisiones + 1) |lat| {
            const v = @as(f32, @floatFromInt(lat)) / @as(f32, @floatFromInt(divisiones));
            const theta = v * std.math.pi;

            for (0..divisiones + 1) |lon| {
                const u = @as(f32, @floatFromInt(lon)) / @as(f32, @floatFromInt(divisiones));
                const phi = u * 2.0 * std.math.pi;

                const pos = rl.Vector3{
                    .x = -@cos(phi) * @sin(theta),
                    .y = @cos(theta),
                    .z = @sin(phi) * @sin(theta),
                };

                try vertices.append(alloc, .{
                    .pos = pos,
                    .uv = .{ u, v },
                });
            }
        }

        const cols = divisiones + 1;
        for (0..divisiones) |lat| { //cada cuadrito se parte en 2 triangulos
            for (0..divisiones) |lon| {
                const p1 = lat * cols + lon;
                const p2 = p1 + cols;

                try caras.append(alloc, .{ p1, p2, p1 + 1 });
                try caras.append(alloc, .{ p2, p2 + 1, p1 + 1 });
            }
        }

        return .{ .vertices = vertices, .caras = caras };
    }

    //se librera memoria
    pub fn deinit(self: *EsferaMalla, alloc: std.mem.Allocator) void {
        self.vertices.deinit(alloc);
        self.caras.deinit(alloc);
    }
};
