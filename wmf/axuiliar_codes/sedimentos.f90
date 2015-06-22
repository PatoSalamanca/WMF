module sedimentos

    implicit none
    contains
    
    !*************************************************************************************************************!
    !Eficiencia de atrapamiento m�todo 1
        subroutine TrapEfic(Te,wi,h,dt)
            !----------------------------------------------------------------!
            !Definici�n de variables
                !Variables de entrada
                integer, intent(in):: dt !delta de tiempo [seg]
                real*4, intent(in):: wi(3),h  !vel de caida [ms-1]
                integer i                
                !Variables de salida
                real, intent(out):: Te(3) !Eficiencia de atrapamiento [%]
            
            !----------------------------------------------------------------!
            !Calculo de la eficiencia para cada fracci�n                                
                do i=1,3
                    if (h/1000>wi(i)*dt) then
                        Te(i)=wi(i)*dt*1000/h
                    else
                        Te(i)=1
                    endif
                enddo          
        end subroutine
    
    !*************************************************************************************************************!
    !Eficiencia de atrapamiento m�todo 2
        subroutine TrapEfic2(Te,wi,h,dx,v)
            !----------------------------------------------------------------!
            !Definici�n de variables
                !Variables de entrada                    
                real*4, intent(in):: wi(3),h
                real, intent(in):: dx,v
                real*4 val,hn
                integer i
                !Variables de salida
                real, intent(out):: Te(3)
                
            !----------------------------------------------------------------!
            !Calculo de la eficiencia para cada fracci�n                      
                hn=h/1000
                do i=1,3
                    val=dx*wi(i)/(v*hn)
                    Te(i)=1-exp(-val)
                enddo
        
        end subroutine
    
    !*************************************************************************************************************!
    !Calcula deposito
        subroutine CalcDep(VS1,VS2,VS3,VD1,VD2,VD3,Te,DEP)
            !----------------------------------------------------------------!
            !Definici�n de variables
                !Variables de entrada
                real, intent(in):: Te(3)
                real, intent(inout) :: VS1,VS2,VS3
                real, intent(out):: DEP(3) !Volumen depositado total en la celda
                !Variables de salida
                real, intent(inout) :: VD1,VD2,VD3
            !----------------------------------------------------------------!
            !Actualiza el dep�sito en el pixel
                VD1=VD1+Te(1)*VS1
                VD2=VD2+Te(2)*VS2
                VD3=VD3+Te(3)*VS3
            !----------------------------------------------------------------!
            !Calcula el vol total depositado en la celda
                DEP=0
                DEP(1)=Te(1)*VS1; DEP(2)=Te(2)*VS2; DEP(3)=Te(3)*VS3;                 
            !----------------------------------------------------------------!
            !Actualiza la suspenci�n en el pixel
                VS1=VS1-Te(1)*VS1
                VS2=VS2-Te(2)*VS2                                
                VS3=VS3-Te(3)*VS3            
        end subroutine
    
    
    
    !*************************************************************************************************************!
    !Calcula Capacidad de arrastre por Kilinc y Richardson modificado
        subroutine CalcQskr(Qskr,area,v,K,C,P,dx,dt,alfa,pend)
            !----------------------------------------------------------------!
            !Definici�n de variables
                !Variables de entrada
                real, intent(in):: K,C,P,dx,alfa,area,v,pend
                integer, intent(in):: dt
                real q
                !Variables de salida
                real, intent(out):: Qskr
            !----------------------------------------------------------------!
            !Calculo de capacidad [m3]
                !Calcula caudal lineal [m2/s]
                q=area*v/dx
                !Calcula capacidad
                Qskr=alfa*(pend**1.664)*(q**2.035)*K*C*P*dx*dt ![m3]
        end subroutine
    
    
    
    !*************************************************************************************************************!
    !CalcSEDlad: calcula sedimentos en ladera basado en lo propuesto por Julien y Rojas (2002)
        subroutine CalcSEDlad(VS1,VS2,VS3,VD1,VD2,VD3,VolSal,PAre,PGra,PArc,Trap,Qskr,v,dt,dx,qsERO,DEP)
            !----------------------------------------------------------------!
            !Definici�n de variables
                !Variables de entrada y salida              
                real, intent(in):: Qskr,v,dx !Capacidad por KR [m3], y vel [m/s], paso de tiempo [seg], long de celda [m]
                integer, intent(in):: dt
                real, intent(in):: PAre,PGra,PArc !Porcentaje de material de cada fracci�n en el pixel [%]
                real, intent(in):: Trap(3) !Eficiencia de atrapamiento en la celda [%]                
                real, intent(inout):: VS1,VS2,VS3 !Tasa de vol en suspenci�n por fracci�n [m3]
                real, intent(inout):: VD1,VD2,VD3 !Tasa de vol en depositaci�n por fracci�n [m3]
                real*4, intent(out)::  qsERO(3) !Vol de erosi�n [m3]
                real*4, intent(inout):: DEP(3) !Volumen depositado en el intervalo
                real, intent(out):: VolSal(3) !Volumen que sale en suspenci�n a la celda destino [m3]

                !Variables de trabajo
                real SUStot, DEPtot,Adv,por(3) !vol en suspenci�n [m3] y vol depositado [m3], transporte en suspenci�n [m3]
                real VolSus(3),VolDep(3)
                real totXSScap, REScap !Capacidades de transporte
                real qsSUStot, qsBMtot !Volumen de sed de cada tipo [m3]
                real qsSUS(3), qsBM(3),qsEROtot !Volumen de sed de cada tipo [m3]
                real TasaTte(3) !Tasa de transporte para cada fracci�n                
                real cap !capacidad de transporte cde ec kr para cada fracci�n
                integer i,j !Para iterar
                
            !----------------------------------------------------------------!
            !Calcula
                !Inicializa volumen transportado para cada tipo en cero
                qsSUStot=0;qsBMtot=0;qsEROtot=0
                qsSUS=0;qsBM=0;qsERO=0                
                SUStot=0;DEPtot=0
                
                !Copia VS y VD
                VolSus(1)=VS1;VolSus(2)=VS2; VolSus(3)=VS3
                VolDep(1)=VD1;VolDep(2)=VD2; VolDep(3)=VD3
                
                !Copia los porcentajes de suelo
                Por(1)=PAre; Por(2)=PGra; Por(3)=PArc
                
                !Calcula SUStot, y DEPtot 
                do i=1,3                    
                    SUStot=SUStot+VolSus(i)
                    DEPtot=DEPtot+VolDep(i)
                enddo
                
                !----------------------------------------------------------
                !Transporte de Suspenci�n                               
                do i=1,3          
                    !Evalua si los sed en suspeci�n son mayores a cero
                    if (VolSus(i)>0.0) then   
                        !Evalua si la capacidad Qsrk es menor a la cant total de sedimentos en suspenci�n
                        if (Qskr<SUStot) then
                            !Volumen que puede ser transportado usando KR
                            cap=Qskr*VolSus(i)/SUStot  ![m3]                         
                            !Volumen que se puede llevar por advecci�n
                            Adv=VolSus(i)*v*dt/(dx+v*dt) ![m3]    
                            !Transporta por suspenci�n lo mayor entre: lo que se puede llevar la capacidad
                            !y lo que se puede llevar por advecci�n
                            qsSUS(i)=max(adv,cap) ![m3]
                        else        
                            !Transporta en suspenci�n todo el volumen de la fracci�n
                            qsSUS(i)=VolSus(i) ![m3]                   
                        endif
                    endif
                    !Va calculando todo lo que se est� transportando en suspenci�n
                    qsSUStot=qsSUStot+qsSUS(i) ![m3]
                enddo
                
                !Calcula la capacidad de transporte de exceso
                totXSScap=max(0.0,Qskr-qsSUStot) ![m3]
                
                !----------------------------------------------------------
                !Transporte de Dep�sito                                              
                !Si hay capacidad excedente y hay volumen depositado remueve lo depositado
                if (totXSScap>0.0 .and. DEPtot>0.0) then
                    !Para cada fracci�n de tama�o 
                    do i=1,3
                        !Si hay sedimentos depositados
                        if (VolDEP(i)>0.0) then    
                            !Observa si la cap excedente es mayor a la cant total depositada
                            if (totXSScap<DEPtot) then
                                !tta porcentaje del volumen depositado de la fracci�n
                                qsBM(i)=totXSScap*volDEP(i)/DEPtot ![m3]
                            else
                                !tta todo el volumen depositado de la fracci�n
                                qsBM(i)=VolDEP(i) ![m3]
                            endif
                        endif
                        !Acumula lo que se tta de cada fracci�n en el tot de transportado por cama
                        qsBMtot=qsBMtot+qsBM(i) ![m3]
                        !Actualiza lo que se fue del vol depositado de cada fracci�n
                        DEP(i)=DEP(i)-qsBM(i) ![m3]
                    enddo
                endif
                
                !Calcula la capacidad residual
                REScap=max(0.0, totXSScap-qsBMtot) ![m3]
                
                !----------------------------------------------------------
                !Transporte de Erosi�n                               
                !Si la capacidad residual es mayor a cero, se presenta erosi�n
                if (REScap>0.0) then
                    !Evalua para cada fracci�n de tama�o
                    do i=1,3
                        !Eroda y agrega a esa fracci�n de acuerdo a la porci�n presente en el suelo
                        qsERO(i)=Por(i)*REScap/100 ![m3]
                        qsEROtot=qsEROtot+qsERO(i) ![m3]
                    end do
                endif
                
                !Actualiza lo que queda en suspenci�n y depositado en cada celda
                VS1=VS1-qsSUS(1);VS2=VS2-qsSUS(2);VS3=VS3-qsSUS(3)
                VD1=VD1-qsBM(1);VD2=VD2-qsBM(2);VD3=VD3-qsBM(3)
                
                !Calcula lo que se va a la celda destino
                VolSal=0
                do i=1,3
                    VolSal(i)=qsSUS(i)+qsBM(i)+qsERO(i)
                enddo                
        end subroutine
        
        
        
    !*************************************************************************************************************!
    !CalcEH: Calcula La concentraci�n de sedimentos por peso mediante Engelund y Hansen (1967)
        subroutine CalcEH(Cw,G,d,v,pen,Area,h)
            !----------------------------------------------------------------!
            !Definici�n de variables
                !Variables de entrada
                real, intent(in):: G,v,pen,Area
                real*4, intent(in):: d(3)
                real, intent(in):: h
                real Rh,L,grav
                real*4 d2
                integer i                
                
                !Variables de salida
                real, intent(out):: Cw(3)
                
            !----------------------------------------------------------------!
            !Calculos
                !Calcula el Rh                
                if (h>0.01) then
                    L=Area*1000/h
                    Rh=L*h/(1000*L+2*h)                
                else
                    Rh=0
                endif    
                !Calcula la concentraci�n
                grav=9.8
                do i=1,3
                    d2=d(i)/1000
                    Cw(i)=0.05*(G/(G-1))*(v*pen)/(sqrt((G-1)*grav*d2))*sqrt((Rh*pen)/((G-1)*d2))
                enddo               
        end subroutine

    !*************************************************************************************************************!
    !CalcSEDCorr: Subrutina para actualizar los sedimentos en la corriente
        subroutine CalcSEDCorr(VS1,VS2,VS3,VD1,VD2,VD3,VolSal,Cw,E,dt,v,dx,DEP)
            !----------------------------------------------------------------!
            !Definici�n de variables
                !Variables de entrada y salida
                real, intent(inout):: VS1,VS2,VS3,VD1,VD2,VD3
                real, intent(out):: VolSal(3)
                real, intent(in):: Cw(3),v,dx
                real*8, intent(in):: E
                integer, intent(in):: dt
                real*4, intent(inout):: DEP(3)
                
                !Variables de trabajo
                real VolSus(3),VolDep(3),Qskr(3),supply,VolEH,Q,AdvF
                real qsSUS(3),qsBM(3),XSScap
                integer i

                
            !----------------------------------------------------------------!
            !Calculos
                !Inicia el transporte de suspenci�n y cama en cero
                qsSUS=0.0; qsBM=0.0
                
                !Copia VS y VD
                VolSus(1)=VS1;VolSus(2)=VS2; VolSus(3)=VS3
                VolDep(1)=VD1;VolDep(2)=VD2; VolDep(3)=VD3
                
                !Inicia el volumen que sale en cero
                VolSal=0
                
                !Para cada fracci�n hace los c�lculos
                do i=1,3
                    !Calcula lo que hay de seimdneots de la fracci�n
                    supply=VolSus(i)+VolDep(i) ![m3] 
                    !inicializa el volumen suspendido de la fracci�n en cero
                    qsSUS(i)=0.0   
                    !Si lo que hay es mayor que cero, lo transporta
                    if (supply>0.0) then
                        !Calcula el vol que puede ser transportado por EH
                        VolEH=E*Cw(i)/2.65 ![m3]
                        !Calcula factor de tte por advecci�n
                        AdvF=min(1.0,v*dt/(dx+v*dt)) ![adim]
                        !AdvF=v*dt/(dx+v*dt)
                        !Realiza el transporte por advecci�n
                        qsSUS(i)=VolSUS(i)*AdvF ![m3]
                        !Calcula la capacidad de Exceso sobrante
                        XSScap=max(0.0,VolEH-qsSUS(i))
                        !Calcula lo que se va de lo depositado
                        qsBM(i)=VolDep(i)*Advf ![m3]
                        qsBM(i)=min(XSScap,qsBM(i)) ![m3] 
!                        if (E<60.0) then
!                            qsBM(i)=0.0;                             
!                        endif
                        DEP(i)=DEP(i)-qsBM(i)                       
                    endif
                enddo
                
                !Actualiza el almacenamiento de VD y VS 
                VS1=VS1-qsSUS(1);VS2=VS2-qsSUS(2);VS3=VS3-qsSUS(3)
                VD1=VD1-qsBM(1);VD2=VD2-qsBM(2);VD3=VD3-qsBM(3)
                
                !Saca lo que se va a la celda destino
                do i=1,3
                    VolSal(i)=qsSUS(i)+qsBM(i) ![m3]
                enddo                
        end subroutine
        
end module