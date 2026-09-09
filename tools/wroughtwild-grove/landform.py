"""Deterministic composition coordinates, Blender/Godot: (x, -z, y)."""
import math
def stream_x(z):
    return -5.8 + 1.0*math.sin(z*.12) + .35*math.sin(z*.31)
def route_x(z):
    return .9*math.sin(z*.15) + .35*math.sin(z*.33)
def height(x,z):
    river=abs(x-stream_x(z))
    bank=1.25*(1-math.exp(-(river/3.0)**4))-.8
    undulation=.13*math.sin(x*.31+z*.19)+.10*math.cos(z*.34-x*.22)
    outside=max(0,abs(x)-9)*.035
    distant_bank=3.4*math.exp(-((z-34)/10)**2)
    return bank + undulation + outside + distant_bank
