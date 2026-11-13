const std = @import("std");
const rl = @import("raylib");

pub const Proyeccion = struct {
    x: f32,
    y: f32,
    z: f32,
};

//camara que se mueve en X y Z
pub const Camera = struct {
    Posicion: rl.Vector3, //donde esta camara
    Adelante: rl.Vector3, //hacia donde ve
    Derecha: rl.Vector3, //eje derecho 
    angulo: f32, //rotacion de manera  horizontal

    pub fn init(posicion: rl.Vector3, angulo_inicial: f32) Camera {
        var cam = Camera{
            .Posicion = posicion,
            .Adelante = .zero(),
            .Derecha = .zero(),
            .angulo = angulo_inicial,
        };
        cam.actualizar();
        return cam;
    }

    //va a responder a donde mira la camara en el eje horizontal
    pub fn actualizar(self: *Camera) void {
        self.Adelante = .{ .x = @cos(self.angulo), .y = 0, .z = @sin(self.angulo) };
        self.Derecha = .{ .x = -@sin(self.angulo), .y = 0, .z = @cos(self.angulo) };
    }

    //apunta la camara hacia un planeta en el plano X-Z
    pub fn mirar_a(self: *Camera, objetivo: rl.Vector3) void {
        const dx = objetivo.x - self.Posicion.x;
        const dz = objetivo.z - self.Posicion.z;
        self.angulo = std.math.atan2(dz, dx);
        self.actualizar();
    }

    //va a convertir un punto en el mundo que es 3D a una coordenada en 2D
    pub fn proyectar(self: Camera, punto: rl.Vector3, ancho: f32, alto: f32, escala_fov: f32) ?Proyeccion {
        const rel = punto.subtract(self.Posicion);
        const z_cam = rel.x * self.Adelante.x + rel.z * self.Adelante.z;

        //se ignora si esta atras o muy cerca de camara 
        if (z_cam <= 0.5) return null;

        const x_cam = rel.x * self.Derecha.x + rel.z * self.Derecha.z;
        const y_cam = rel.y;

        const aspecto = ancho / alto;
        const ndc_x = x_cam / (z_cam * escala_fov * aspecto);
        const ndc_y = y_cam / (z_cam * escala_fov);

        return .{
            .x = (ndc_x + 1.0) * 0.5 * ancho,
            .y = (1.0 - ndc_y) * 0.5 * alto,
            .z = z_cam,
        };
    }
};
