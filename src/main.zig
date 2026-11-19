const std = @import("std");
const rl = @import("raylib");
const Framebuffer = @import("framebuffer.zig").Framebuffer;
const Camera = @import("camera.zig").Camera;
const EsferaMalla = @import("esfera.zig").EsferaMalla;
const bar = @import("bar.zig");
const tex = @import("texture.zig");
const htmlColor = @import("cute_colors.zig").htmlColor;

//confi
const ancho = 800;
const alto = 600;
const num_estrellas = 220;

const Astro = struct { // para sol o un planeta
    radio: f32,
    distancia_sol: f32,
    velocidad_orbita: f32,
    angulo_orbita: f32,
    indice_textura: usize,
    es_sol: bool = false,
    posicion: rl.Vector3 = .{ .x = 0, .y = 0, .z = 0 },
};

pub fn main() !void {
    const alloc = std.heap.page_allocator;

    rl.initWindow(ancho, alto, "space traveler project3");
    rl.setTraceLogLevel(.warning);
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var framebuffer = try Framebuffer.init(alloc, ancho, alto);
    defer framebuffer.liberar(alloc);

    //red de esfera para el sol y planetas
    var malla_esfera = try EsferaMalla.crear(alloc, 12);
    defer malla_esfera.deinit(alloc);

    // las mismas texturas diferentes que se usaron para el raytracer
    const texturas = [_]tex.Textura{
        //0: Sol (amarillo y naranja)
        try tex.crear_franjas(alloc, 32, 4, htmlColor("#fff066"), htmlColor("#ff8800")),
        //1: Planeta rocoso (tablero gris)
        try tex.crear_tablero(alloc, 32, 4, htmlColor("#a09080"), htmlColor("#706050")),
        //2: Planeta tierra (tablero azul y verde)
        try tex.crear_tablero(alloc, 32, 8, htmlColor("#2060b0"), htmlColor("#309050")),
        //3: Planeta marte (ladrillos rojizos)
        try tex.crear_ladrillos(alloc, 32, htmlColor("#e04020"), htmlColor("#602015")),
        //4: Gigante gaseoso (franjas cafe y crema)
        try tex.crear_franjas(alloc, 32, 4, htmlColor("#d0a060"), htmlColor("#886030")),
    };

    //ahora si el sistema solar que es lit el  sol con los 4 planetas 
    var astros = [_]Astro{
        //0: Sol en el centro
        .{ .radio = 3.8, .distancia_sol = 0.0, .velocidad_orbita = 0.0, .angulo_orbita = 0.0, .indice_textura = 0, .es_sol = true },
        //1: Planeta rocoso
        .{ .radio = 1.2, .distancia_sol = 10.0, .velocidad_orbita = 0.7, .angulo_orbita = 0.0, .indice_textura = 1 },
        //2: Planeta tierra
        .{ .radio = 1.7, .distancia_sol = 17.0, .velocidad_orbita = 0.45, .angulo_orbita = 1.5, .indice_textura = 2 },
        //3: Planeta marte
        .{ .radio = 1.5, .distancia_sol = 25.0, .velocidad_orbita = 0.3, .angulo_orbita = 3.2, .indice_textura = 3 },
        //4: Gigante gaseoso
        .{ .radio = 2.5, .distancia_sol = 34.0, .velocidad_orbita = 0.18, .angulo_orbita = 4.8, .indice_textura = 4 },
    };

    //se agregan stars  para el skybox
    var estrellas: [num_estrellas]rl.Vector3 = undefined;
    for (0..num_estrellas) |i| {
        const fi: f32 = @floatFromInt(i);
        const y = 0.6 - 1.2 * @mod(fi * 0.618, 1.0);
        const ang = fi * 2.4;
        estrellas[i] = .{ .x = @cos(ang), .y = y, .z = @sin(ang) };
    }

    //camara que se mueve en x,z con altura establecida
    var camara = Camera.init(.{ .x = 0, .y = 0, .z = 28 }, -std.math.pi / 2.0);
    const escala_fov = @tan(std.math.pi / 6.0);

    while (!rl.windowShouldClose()) {
        const dt = rl.getFrameTime();

        //actualiza posicion de cada planeta con respecto al sol
        for (0..astros.len) |i| {
            astros[i].angulo_orbita += astros[i].velocidad_orbita * dt;
            astros[i].posicion = .{
                .x = @cos(astros[i].angulo_orbita) * astros[i].distancia_sol,
                .y = 0,
                .z = @sin(astros[i].angulo_orbita) * astros[i].distancia_sol,
            };
        }

        //mov de camara en  los 2 ejes 
        const vel_giro: f32 = 1.6;
        const vel_mov: f32 = 14.0;
        if (rl.isKeyDown(.a) or rl.isKeyDown(.left)) camara.angulo -= vel_giro * dt;
        if (rl.isKeyDown(.d) or rl.isKeyDown(.right)) camara.angulo += vel_giro * dt;
        camara.actualizar(); //para girar

        if (rl.isKeyDown(.w) or rl.isKeyDown(.up)) {
            camara.Posicion.x += camara.Adelante.x * vel_mov * dt;
            camara.Posicion.z += camara.Adelante.z * vel_mov * dt;
        }
        if (rl.isKeyDown(.s) or rl.isKeyDown(.down)) {
            camara.Posicion.x -= camara.Adelante.x * vel_mov * dt;
            camara.Posicion.z -= camara.Adelante.z * vel_mov * dt;
        } //para ir adelante o atras

        //con apachar 1 al 5  muestra rapido los objetos
        const teclas = [_]rl.KeyboardKey{ .one, .two, .three, .four, .five };
        for (teclas, 0..) |t, i| {
            if (rl.isKeyPressed(t)) {
                const p = astros[i].posicion;
                camara.Posicion = .{ .x = p.x, .y = 0, .z = p.z + astros[i].radio * 3.2 + 3.0 };
                camara.mirar_a(p);
            }
        }

        //para que la camara no atraviese las cosas
        evitar_colisiones(&camara.Posicion, &astros);

        framebuffer.limpiar();

        //primero se dibuja el skybox de estrellas
        dibujar_skybox(&framebuffer, camara, &estrellas, escala_fov);

        //luego los planetas y sol
        const pos_sol = astros[0].posicion;
        for (astros) |astro| {
            dibujar_astro(
                &framebuffer,
                malla_esfera,
                astro,
                texturas[astro.indice_textura],
                pos_sol,
                camara,
                escala_fov,
            );
        }

        try framebuffer.mostrar();
    }
}

//fun para que cam no atraviese cosas
fn evitar_colisiones(pos_camara: *rl.Vector3, astros: []const Astro) void {
    for (astros) |astro| {
        const diff = pos_camara.subtract(astro.posicion);
        const dist = diff.length();
        const min_dist = astro.radio + 1.5;

        if (dist < min_dist and dist > 0.0001) {
            pos_camara.* = astro.posicion.add(diff.normalize().scale(min_dist));
        }
    }
}

// fun q proyectas las stars
fn dibujar_skybox(fb: *Framebuffer, camara: Camera, estrellas: []const rl.Vector3, escala_fov: f32) void {
    const w_f: f32 = @floatFromInt(fb.ancho);
    const h_f: f32 = @floatFromInt(fb.alto);

    for (estrellas) |dir| {
        const punto = camara.Posicion.add(dir.scale(100.0));
        const proy = camara.proyectar(punto, w_f, h_f, escala_fov) orelse continue;
        fb.poner_pixel(@intFromFloat(proy.x), @intFromFloat(proy.y), .white);
    }
}

//dibuja objetos usando las  coordenadas baricentricas y la iluminacion del sol
fn dibujar_astro(
    fb: *Framebuffer,
    malla: EsferaMalla,
    astro: Astro,
    textura: tex.Textura,
    pos_sol: rl.Vector3,
    camara: Camera,
    escala_fov: f32,
) void {
    const w_f: f32 = @floatFromInt(fb.ancho);
    const h_f: f32 = @floatFromInt(fb.alto);
    const pixeles = fb.obtener_pixeles();

    for (malla.caras.items) |cara| {
        const v0 = malla.vertices.items[cara[0]];
        const v1 = malla.vertices.items[cara[1]];
        const v2 = malla.vertices.items[cara[2]];

        const p0_mundo = astro.posicion.add(v0.pos.scale(astro.radio));
        const p1_mundo = astro.posicion.add(v1.pos.scale(astro.radio));
        const p2_mundo = astro.posicion.add(v2.pos.scale(astro.radio));

        const proy0 = camara.proyectar(p0_mundo, w_f, h_f, escala_fov) orelse continue;
        const proy1 = camara.proyectar(p1_mundo, w_f, h_f, escala_fov) orelse continue;
        const proy2 = camara.proyectar(p2_mundo, w_f, h_f, escala_fov) orelse continue;

        const a = bar.Punto{ .x = proy0.x, .y = proy0.y };
        const b = bar.Punto{ .x = proy1.x, .y = proy1.y };
        const c = bar.Punto{ .x = proy2.x, .y = proy2.y };

        //como el  el sol brilla con todo entonces los planetas se iluminan segun la direccion hacia el sol
        var intensidad: f32 = 1.0;
        if (!astro.es_sol) {
            const normal = v0.pos;
            const dir_luz = pos_sol.subtract(p0_mundo).normalize();
            intensidad = @max(0.15, normal.dotProduct(dir_luz));
        }

        //bounding box recortada a pantalla, con ayuda de la IA
        const min_x = @min(a.x, @min(b.x, c.x));
        const max_x = @max(a.x, @max(b.x, c.x));
        const min_y = @min(a.y, @min(b.y, c.y));
        const max_y = @max(a.y, @max(b.y, c.y));

        const w_max: f32 = @floatFromInt(fb.ancho - 1);
        const h_max: f32 = @floatFromInt(fb.alto - 1);
        if (max_x < 0 or min_x > w_max or max_y < 0 or min_y > h_max) continue;

        const x0: usize = @intFromFloat(std.math.clamp(@floor(min_x), 0.0, w_max));
        const x1: usize = @intFromFloat(std.math.clamp(@ceil(max_x), 0.0, w_max));
        const y0: usize = @intFromFloat(std.math.clamp(@floor(min_y), 0.0, h_max));
        const y1: usize = @intFromFloat(std.math.clamp(@ceil(max_y), 0.0, h_max));

        var y = y0;
        while (y <= y1) : (y += 1) {
            var x = x0;
            while (x <= x1) : (x += 1) { 
                const p = bar.Punto{
                    .x = @as(f32, @floatFromInt(x)) + 0.5,
                    .y = @as(f32, @floatFromInt(y)) + 0.5,
                };

                const coords = bar.calcular(p, a, b, c) orelse break;
                if (!bar.esta_dentro(coords)) continue;

                const z = coords.u * proy0.z + coords.v * proy1.z + coords.w * proy2.z;//tambien se sugerio ayuda de la IA -_-
                const idx = y * fb.ancho + x;
                if (z >= fb.zbuffer[idx]) continue;

                const u = coords.u * v0.uv[0] + coords.v * v1.uv[0] + coords.w * v2.uv[0];
                const v = coords.u * v0.uv[1] + coords.v * v1.uv[1] + coords.w * v2.uv[1];

                const color_tex = textura.muestrear(u, v).scale(intensidad);
                fb.zbuffer[idx] = z;
                pixeles[idx] = tex.V3ToColor(color_tex);
            }
        }
    }
}
