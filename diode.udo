; Diode Ladder Filter
; 
; Based on code by Will Pirkle, presented in:
;
; http://www.willpirkle.com/Downloads/AN-6DiodeLadderFilter.pdf
; 
; and in his book "Designing software synthesizer plug-ins in C++ : for 
; RackAFX, VST3, and Audio Units"
;
; UDO version by Steven Yi (2016.xx.xx)


opcode diode_ladder, a, akk

  ain, kcf, kk xin
  aout init 0

  ; pre-warp the cutoff- these are bilinear-transform filters
  kwd = 2 * $M_PI * kcf
  iT  = 1/sr 
  kwa = (2/iT) * tan(kwd * iT/2) 
  kg  = kwa * iT/2 

  kG4 = 0.5 * kg / (1.0 + kg)
  kG3 = 0.5 * kg / (1.0 + kg - 0.5 * kg * kG4)
  kG2 = 0.5 * kg / (1.0 + kg - 0.5 * kg * kG3)
  kG1 = kg / (1.0 + kg - kg * kG2)

  kGAMMA = kG4 * kG3 * kG2 * kG1

  kSG1 = kG4 * kG3 * kG2 
  kSG2 = kG4 * kG3  
  kSG3 = kG4 
  kSG4 = 1.0 

  kalpha = kg / (1.0 + kg)

  kbeta1 = 1.0 / (1.0 + kg - kg * kG2)
  kbeta2 = 1.0 / (1.0 + kg - 0.5 * kg * kG3)
  kbeta3 = 1.0 / (1.0 + kg - 0.5 * kg * kG4)
  kbeta4 = kalpha 

  kgamma1 = 1.0 + kG1 * kG2
  kgamma2 = 1.0 + kG2 * kG3
  kgamma3 = 1.0 + kG3 * kG4

  kdelta1 = kg
  kdelta2 = 0.5 * kg
  kdelta3 = 0.5 * kg
  kdelta4 = 0.0 

  kepsilon1 = kG2
  kepsilon2 = kG3
  kepsilon3 = kG4

  ka1 init 1.0
  ka2 init 0.5 
  ka3 init 0.5 
  ka4 init 0.5 

  ;; state for each 1-pole's integrator 
  kz1 init 0
  kz2 init 0
  kz3 init 0
  kz4 init 0

  kindx = 0

  while kindx < ksmps do

    kin = ain[kindx]

    ;; feedback inputs 
    kfb4 = kbeta4 * kz4 
    kfb3 = kbeta3 * (kz3 + kfb4 * kdelta3)
    kfb2 = kbeta2 * (kz2 + kfb3 * kdelta2)

    ;; feedback process

    kfbo1 = (kbeta1 * (kz1 + kfb2 * kdelta1))
    kfbo2 = (kbeta2 * (kz2 + kfb3 * kdelta2))    
    kfbo3 = (kbeta3 * (kz3 + kfb4 * kdelta3))
    kfbo4 = kfb4 

    kSIGMA = kSG1 * kfbo1 +
             kSG2 * kfbo2 +
             kSG3 * kfbo3 +
             kSG4 * kfb4 

    ;; TODO: non-linear processing

    ;; form input to loop
    kun = (kin - kk * kSIGMA) / (1.0 + kk * kGAMMA)

    ;; 1st stage
    kxin = (kun * kgamma1 + kfb2 + kepsilon1 * kfbo1)
    kv = (ka1 * kxin - kz1) * kalpha 
    klp = kv + kz1
    kz1 = klp + kv

    ;; 2nd stage
    kxin = (klp * kgamma2 + kfb3 + kepsilon2 * kfbo2)
    kv = (ka2 * kxin - kz2) * kalpha 
    klp = kv + kz2
    kz2 = klp + kv

    ;; 3rd stage
    kxin = (klp * kgamma3 + kfb4 + kepsilon3 * kfbo3)
    kv = (ka3 * kxin - kz3) * kalpha 
    klp = kv + kz3
    kz3 = klp + kv

    ;; 4th stage
    kv = (ka4 * klp - kz4) * kalpha 
    klp = kv + kz4
    kz4 = klp + kv

    aout[kindx] = klp

    kindx += 1
  od

  xout aout

endop
