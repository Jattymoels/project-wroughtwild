// Each existing cave field has two octaves. A column keeps its x/z lattice
// coordinates and x interpolations while y remains in the same lattice cell.
// All arithmetic follows valueNoise3/fbm3's original order; this stores only
// repeated pure results, never a random stream or persistent world state.
class CaveColumnNoise {
    struct Octave {
        uint64_t seed;
        uint32_t salt;
        double frequency,tx,tz;
        int x0,z0,y0=0;
        bool ready=false;
        double x00=0,x10=0,x01=0,x11=0;

        Octave(uint64_t seedIn,int x,int z,double frequencyIn,uint32_t saltIn)
            :seed(seedIn),salt(saltIn),frequency(frequencyIn) {
            const double sampleX=x*frequency,sampleZ=z*frequency;
            x0=static_cast<int>(std::floor(sampleX));
            z0=static_cast<int>(std::floor(sampleZ));
            tx=smoothstep(sampleX-x0);tz=smoothstep(sampleZ-z0);
        }
        double sample(int y) {
            const double sampleY=y*frequency;
            const int nextY=static_cast<int>(std::floor(sampleY));
            const double ty=smoothstep(sampleY-nextY);
            if(!ready||nextY!=y0){
                y0=nextY;ready=true;
                const double c000=lattice3(seed,x0,y0,z0,salt);
                const double c100=lattice3(seed,x0+1,y0,z0,salt);
                const double c010=lattice3(seed,x0,y0+1,z0,salt);
                const double c110=lattice3(seed,x0+1,y0+1,z0,salt);
                const double c001=lattice3(seed,x0,y0,z0+1,salt);
                const double c101=lattice3(seed,x0+1,y0,z0+1,salt);
                const double c011=lattice3(seed,x0,y0+1,z0+1,salt);
                const double c111=lattice3(seed,x0+1,y0+1,z0+1,salt);
                x00=c000+(c100-c000)*tx;
                x10=c010+(c110-c010)*tx;
                x01=c001+(c101-c001)*tx;
                x11=c011+(c111-c011)*tx;
            }
            const double y0v=x00+(x10-x00)*ty;
            const double y1v=x01+(x11-x01)*ty;
            return y0v+(y1v-y0v)*tz;
        }
    };
    Octave octaves[2];
public:
    CaveColumnNoise(uint64_t seed,int x,int z,double frequency,uint32_t salt)
        :octaves{{seed,x,z,frequency,salt},{seed,x,z,frequency*2.0,salt+101}}{}
    double sample(int y) {
        double total=0,amplitude=1,sum=0;
        for(auto& octave:octaves){
            total+=octave.sample(y)*amplitude;
            sum+=amplitude;amplitude*=0.5;
        }
        return total/sum;
    }
};
