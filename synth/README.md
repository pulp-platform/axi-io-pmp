



```bash
./bender script synopsys > analyze.tcl
cp analyze.tcl synth/synopsys/
```

```bash
cd synth/
icdesign gf22 -update all -nogui
```


```bash

synopsys-2021.06 dc_shell

source synth.tcl
```