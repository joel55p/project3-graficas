//code que se reuso del lab triangulos baricentricos
const std = @import("std");

pub const Punto = struct { x: f32, y: f32 };

//siempre deben de sumar 1
pub const Coordenadas = struct { u: f32, v: f32, w: f32 };

//el signo depende de que si los vertices van en sentido horario o al reves
pub fn area_doble(a: Punto, b: Punto, c: Punto) f32 {
    return (b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y);
}

//coordenadas baricentricas de p respecto al triangulo a, b, c
pub fn calcular(p: Punto, a: Punto, b: Punto, c: Punto) ?Coordenadas {
    const total = area_doble(a, b, c);
    if (@abs(total) < 1e-6) return null; //devuelve null si el triangulo tiene area = 0

    return .{
        .u = area_doble(p, b, c) / total,
        .v = area_doble(a, p, c) / total,
        .w = area_doble(a, b, p) / total,
    };
}

//p esta dentro si ninguna coordenada es negativa
pub fn esta_dentro(coords: Coordenadas) bool {
    return coords.u >= 0 and coords.v >= 0 and coords.w >= 0;
}
