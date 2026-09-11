"""ART-02 landform copied unchanged. Godot z is negated from its forward walk."""
import math
def stream_x(z):
    return -5.8 + math.sin(z*.12) + .35*math.sin(z*.31)
def route_x(z):
    return .9*math.sin(z*.15) + .35*math.sin(z*.33)
def analytic_height(x,z):
    river=abs(x-stream_x(z))
    bank=1.25*(1-math.exp(-(river/3.0)**4))-.8
    undulation=.13*math.sin(x*.31+z*.19)+.10*math.cos(z*.34-x*.22)
    outside=max(0,abs(x)-9)*.035
    distant_bank=3.4*math.exp(-((z-34)/10)**2)
    return bank+undulation+outside+distant_bank
def height(x,z):
    # Exact barycentric height of the retained 0.5 m ground triangles.
    a=math.floor(x*2)/2;b=math.floor(z*2)/2;u=(x-a)*2;v=(z-b)*2
    h00=analytic_height(a,b);h10=analytic_height(a+.5,b)
    h01=analytic_height(a,b+.5);h11=analytic_height(a+.5,b+.5)
    return h00+u*(h10-h00)+v*(h01-h00) if u+v<=1 else h11+(1-u)*(h01-h11)+(1-v)*(h10-h11)
