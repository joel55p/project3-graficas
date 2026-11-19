# Space Travel - Software Renderer

Simulacion del sistema solar usando un software renderer en Zig y Raylib.

## Referencias 
- [Referencias bibliograficas](refes/refes.pdf)
## Controles

| Tecla | 
|-------|
| `W / S` (o Flechas Arriba/Abajo) -> Avanzar / retroceder 
| `A / D` (o Flechas Izquierda/Derecha) -> girar camara a los lados 
| `1 - 5` -> Fast Travel al Sol o a cada planeta 

## Ejecucion

```bash
zig build run -Doptimize=ReleaseFast
```

## Lo que se implemento REAL
10 Puntos por cada planeta o luna en el sistema. Para un máximo de 50 puntos. Para que cuenten, deben tener por lo menos una textura diferente.(50pts)
10 Puntos si sus estrellas realmente iluminan a los planetas.
10 Puntos por que el programa corra bien la mayoría del tiempo.
10 Puntos más si no se atasca inclusive estando cerca de los objetos.
10 Puntos por implementar una manera de viajar rápido por el sistema solar. (Piensen en el fast travel de un videojuego)
10 Puntos por crear un skybox que muestre estrellas en el horizonte
10 Puntos por implementar condicionales que eviten que la nave/camara atraviese los elementos de su sistema solar.

100-110 pts
## Video
[Ver video en YouTube](https://youtu.be/GqIGg-4UhcE)


