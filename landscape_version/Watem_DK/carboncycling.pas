unit CarbonCycling;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, RData, GData, surface, variables, math;

type
  vector_single = array of single;
  vector_double =array of double;
  vector_integer =array of integer;

 procedure Carbon_Initilization;
 procedure Texture_Initialization;
 procedure CS137_Initialization;
 procedure Evolution_erosion(ero_rate: double;var Profile: vector_single);
 procedure Evolution_deposition(depo_rate: double; content:single; var Profile: vector_single);
 Procedure Carbon_Cycling(k1,k2,k3,hAS,hAP,hSP : single;Cin,r: vector_single;var A,S,P: vector_single);
 Function mineralization_extrapolation:vector_single;
 Function input_allocation:vector_single;
 Function input_allocation2:vector_single;
 Procedure C14_decay(var profile:vector_single);
 Procedure Cs137_decay(var profile:vector_single);
 Procedure Cs137_fallout(fallout_rate:single;var profile:vector_single);
 procedure tillage_mix (var profile: vector_single);
 Function deltaC13_to_ratio(deltaC13:single):single;
 Function ratio_to_deltaC13(ratio:single):single;
 Function DeltaC14_to_ratio(DeltaC14,deltaC13:single):single;
 Function ratio_to_DeltaC14(ratio,deltaC13:single):single;
 Procedure Adevection_diffusion(K,v:vector_single;var C:vector_single;unstable:boolean);
 Function K_coefficient:vector_single;
 Function v_coefficient:vector_single;
 Function ER_erosion(waterero:single):single;
 Function ER_deposition(waterero:single):single;
implementation

procedure Carbon_Initilization;
var
 i,j,k,t,m: integer;
 Cin,r,C13_in,C14_in: array of single;
 A12_profile, S12_profile,P12_profile: array of single;
 C13C12ratio_profile: array of single;
 A13_profile, S13_profile, P13_profile: array of single;
 C13C12ratio_top, C13C12ratio_bot: single;
 C14C12ratio_profile: array of single;
 A14_profile, S14_profile, P14_profile: array of single;
 C14C12ratio_top, C14C12ratio_bot: single;
 C13C12ratio_input,C14C12ratio_input: single;
 deltaC13_input,DeltaC14_input:single;
 C13_input, C14_input:textfile;
 C13_num, C14_num: integer;
 C13_year, C14_year:array of integer;
 C13_series,C14_series:array of single;
 C_file,C_file2:textfile;
 temp_C13_profile,temp_C14_profile:array of single;
 year_loop,year_loop_num:integer;
 K_coe,v_coe:array of single;
 start_year,end_year:integer;
 c_profile_temp:array of single;
 temp_Cstock: single;
begin

  SetLength(A12_profile,layer_num+2);
  SetLength(S12_profile,layer_num+2);
  SetLength(P12_profile,layer_num+2);

  SetLength(C13C12ratio_profile,layer_num+2);
  SetLength(A13_profile,layer_num+2);
  SetLength(S13_profile,layer_num+2);
  SetLength(P13_profile,layer_num+2);

  SetLength(C14C12ratio_profile,layer_num+2);
  SetLength(A14_profile,layer_num+2);
  SetLength(S14_profile,layer_num+2);
  SetLength(P14_profile,layer_num+2);

  Setlength(C13_in,layer_num+2);
  Setlength(C14_in,layer_num+2);
  Setlength(c_profile_temp,layer_num+2);

  end_year:=erosion_start_year-1;
  start_year:=end_year-time_equilibrium;

  C13C12ratio_top:=deltaC13_to_ratio(deltaC13_ini_top);
  C13C12ratio_bot:=deltaC13_to_ratio(deltaC13_ini_bot);

  C14C12ratio_top:=DeltaC14_to_ratio(DeltaC14_ini_top,deltaC13_ini_top);
  C14C12ratio_bot:=DeltaC14_to_ratio(DeltaC14_ini_bot,deltaC13_ini_bot);

  Cin:=input_allocation2;
  r:=mineralization_extrapolation;
  K_coe:=K_coefficient;
  v_coe:=v_coefficient;

  for i:=1 to layer_num do
     begin
       A12_profile[i]:=Cin[i]/(r[i]*k1);
       S12_profile[i]:=hAS*Cin[i]/(r[i]*k2);
       P12_profile[i]:=(hAp*k1*A12_profile[i]+hSP*k2*S12_profile[i])/k3;

       C13C12ratio_profile[i]:=C13C12ratio_top-(i-1)*(C13C12ratio_top-C13C12ratio_bot)/layer_num;
       A13_profile[i]:=A12_profile[i]*C13C12ratio_profile[i];
       S13_profile[i]:=S12_profile[i]*C13C12ratio_profile[i];
       P13_profile[i]:=P12_profile[i]*C13C12ratio_profile[i];

       C14C12ratio_profile[i]:=C14C12ratio_top-(i-1)*(C14C12ratio_top-C14C12ratio_bot)/layer_num;
       A14_profile[i]:=A12_profile[i]*C14C12ratio_profile[i];
       S14_profile[i]:=S12_profile[i]*C14C12ratio_profile[i];
       P14_profile[i]:=P12_profile[i]*C14C12ratio_profile[i];
     end;

  assignfile(C_file2,'F:/Geoscientific model development/integrate_model/C_profle3.txt');
  setlength(temp_C13_profile,layer_num+2);
  for i:= 1 to layer_num do
     begin
         temp_C13_profile[i]:=ratio_to_deltaC13((A13_profile[i]+S13_profile[i]+P13_profile[i])/(A12_profile[i]+S12_profile[i]+P12_profile[i]));
     end;
  rewrite(C_file2);
  for i:=1 to layer_num do
     begin
        writeln(C_file2,i,char(9), A12_profile[i],char(9),S12_profile[i],char(9),P12_profile[i],char(9),
                       A13_profile[i],char(9),S13_profile[i],char(9),P13_profile[i],char(9),
                       A14_profile[i],char(9),S14_profile[i],char(9),P14_profile[i],char(9),temp_C13_profile[i]);
     end;
  closefile(C_file2);

  assignfile(C13_input,c13filename);
  reset(C13_input);
  readln(C13_input,C13_num);
  setlength(C13_year,C13_num+2);
  setlength(C13_series,C13_num+2);

  for i:=1 to C13_num do
     begin
        readln(C13_input,C13_year[i],C13_series[i]);
     end;
  closefile(C13_input);

  assignfile(C14_input,c14filename);
  reset(C14_input);
  readln(C14_input,C14_num);
  setlength(C14_year,C14_num+2);
  setlength(C14_series,C14_num+2);

  for i:=1 to C14_num do
     begin
        readln(C14_input,C14_year[i],C14_series[i]);
     end;
  closefile(C14_input);


  year_loop_num:=floor(time_equilibrium/time_step);
  for year_loop:=1 to year_loop_num do
     begin
       t:=start_year+(year_loop-1)*time_step;

     if (t<C13_year[1]) OR (t>C13_year[C14_num]) then
        begin
            DeltaC13_input:=DeltaC13_input_default;
        end
      else
        begin
            for m:=1 to C13_num do
               begin
                  if (t=C13_year[m]) then
                     DeltaC13_input:=C13_series[m]; // it is ratio, not need to multiply the time-step
               end;

        end;

  C13C12ratio_input:=deltaC13_to_ratio(deltaC13_input);


  for i:=1 to layer_num  do
     begin
        C13_in[i]:=Cin[i]*C13C12ratio_input;
     end;


      if (t<C14_year[1]) OR (t>C14_year[C14_num]) then
        begin
            DeltaC14_input:=DeltaC14_input_default;
        end
      else
        begin
            for m:=1 to C14_num do
               begin
                  if (t=C14_year[m]) then
                     DeltaC14_input:=C14_series[m]; // it is ratio, not need to multiply the time-step
               end;

        end;

  C14C12ratio_input:=DeltaC14_to_ratio(DeltaC14_input,deltaC13_input);

  for i:= 1 to layer_num do
     begin
        C14_in[i]:=Cin[i]*C14C12ratio_input;
     end;

       Carbon_Cycling(k1,k2,k3,hAS,hAP,hSP,Cin,r,A12_profile,S12_profile,P12_profile);
       Carbon_Cycling(k1*C13_discri,k2*C13_discri,k3*C13_discri,hAS,hAP,hSP,C13_in,r,A13_profile,S13_profile,P13_profile);
       Carbon_Cycling(k1*C14_discri,k2*C14_discri,k3*C14_discri,hAS,hAP,hSP,C14_in,r,A14_profile,S14_profile,P14_profile);

       C14_decay(A14_profile);
       C14_decay(S14_profile);
       C14_decay(P14_profile);

       if unstable= FALSE then
                begin
                    Adevection_diffusion(K_coe,v_coe,A12_profile,unstable);
                    Adevection_diffusion(K_coe,v_coe,S12_profile,unstable);
                    Adevection_diffusion(K_coe,v_coe,P12_profile,unstable);
                    Adevection_diffusion(K_coe,v_coe,A13_profile,unstable);
                    Adevection_diffusion(K_coe,v_coe,S13_profile,unstable);
                    Adevection_diffusion(K_coe,v_coe,P13_profile,unstable);
                    Adevection_diffusion(K_coe,v_coe,A14_profile,unstable);
                    Adevection_diffusion(K_coe,v_coe,S14_profile,unstable);
                    Adevection_diffusion(K_coe,v_coe,P14_profile,unstable);
                end;
       tillage_mix(A12_profile); tillage_mix(S12_profile); tillage_mix(P12_profile);
       tillage_mix(A13_profile); tillage_mix(S13_profile); tillage_mix(P13_profile);
       tillage_mix(A14_profile); tillage_mix(S14_profile); tillage_mix(P14_profile);
     end;

  for i:= 1 to nrow do
     for j:=1 to ncol do
        for k:=1 to layer_num do
        begin
            A12[k,i,j]:=A12_profile[k];
            S12[k,i,j]:=S12_profile[k];
            P12[k,i,j]:=P12_profile[k];
            A13[k,i,j]:=A13_profile[k];
            S13[k,i,j]:=S13_profile[k];
            P13[k,i,j]:=P13_profile[k];
            A14[k,i,j]:=A14_profile[k];
            S14[k,i,j]:=S14_profile[k];
            P14[k,i,j]:=P14_profile[k];
        end;

  setlength(temp_C13_profile,layer_num+2);
  for i:= 1 to layer_num do
     begin
         temp_C13_profile[i]:=ratio_to_deltaC13((A13_profile[i]+S13_profile[i]+P13_profile[i])/(A12_profile[i]+S12_profile[i]+P12_profile[i]));
     end;

  setlength(temp_C14_profile,layer_num+2);
  for i:=1 to layer_num do
     begin
        temp_C14_profile[i]:=ratio_to_DeltaC14((A14_profile[i]+S14_profile[i]+P14_profile[i])/(A12_profile[i]+S12_profile[i]+P12_profile[i]),temp_C13_profile[i]);
     end;

  assignfile(C_file,'F:/Geoscientific model development/integrate_model\C_profile.txt');
  rewrite(C_file);
  for i:=1 to layer_num do
     begin
        writeln(C_file,i,char(9), A12_profile[i],char(9),S12_profile[i],char(9),P12_profile[i],char(9),
                       A13_profile[i],char(9),S13_profile[i],char(9),P13_profile[i],char(9),
                       A14_profile[i],char(9),S14_profile[i],char(9),P14_profile[i],char(9),temp_C13_profile[i],char(9),temp_C14_profile[i]);
     end;
  closefile(C_file);

  for i:=1 to layer_num do
     begin
       c_profile_temp[i]:= A12_profile[i]+ S12_profile[i]+P12_profile[i]+A13_profile[i]+S13_profile[i]+P13_profile[i]+A14_profile[i]+S14_profile[i]+P14_profile[i];
     end;

  temp_Cstock:=0;
        for k:=1 to layer_num do
              begin
                temp_Cstock:=temp_Cstock+c_profile_temp[k]*depth_interval;
                end;

  for i:=1 to nrow do
        for j:=1 to ncol do
          begin
                C_STOCK_equili[i,j]:=temp_Cstock/100/100*BD; // unit kg/m2
            end;

end;


procedure Texture_initialization;
var
 i,j,k :integer;
 Rock_ini_top, Rock_ini_bot : single;
 sand_profile, silt_profile, clay_profile, rock_profile : array of single;

 begin

  SetLength(Sand_profile,layer_num+2);
  SetLength(Silt_profile,layer_num+2);
  SetLength(Clay_profile,layer_num+2);
  SetLength(Rock_profile,layer_num+2);

  Rock_ini_top:=100-Sand_ini_top-Silt_ini_top-Clay_ini_top;
  Rock_ini_bot:=100-Sand_ini_bot-Silt_ini_bot-Clay_ini_bot;

  for i:=1 to layer_num do
  begin
     Sand_profile[i]:=Sand_ini_top-(i-1)*(Sand_ini_top-Sand_ini_bot);
     Silt_profile[i]:=Silt_ini_top-(i-1)*(Silt_ini_top-Silt_ini_bot);
     Clay_profile[i]:=Clay_ini_top-(i-1)*(Clay_ini_top-Clay_ini_bot);
     Rock_profile[i]:=Rock_ini_top-(i-1)*(Rock_ini_top-Rock_ini_bot);
  end;

  tillage_mix(Clay_profile); tillage_mix(Silt_profile); tillage_mix(Sand_profile); tillage_mix(Rock_profile);

  for i:= 1 to nrow do
     for j:=1 to ncol do
        for k:=1 to layer_num do
        begin
            SAND[k,i,j]:=Sand_profile[k];
            SILT[k,i,j]:=Silt_profile[k];
            CLAY[k,i,j]:=Clay_profile[k];
            ROCK[k,i,j]:=Rock_profile[k];
        end;

 end;

procedure CS137_Initialization;
var
 i,j,k,t,m: integer;
 Cs137_profile:array of single;
 Rate_Cs137_input:single;
 Cs137_input:textfile;
 Cs137_num: integer;
 Cs137_year:array of integer;
 Cs137_series:array of single;
 year_loop,year_loop_num:integer;
 K_coe,v_coe:array of single;
 start_year,end_year:integer;

  C_file:textfile;

 begin
    setlength(Cs137_profile,layer_num+2);
    for k:=1 to layer_num do
            begin
                CS137_profile[k]:=1e-5;
            end;

  end_year:=erosion_start_year-1;
  start_year:=end_year-time_equilibrium;
  K_coe:=K_coefficient;
  v_coe:=v_coefficient;

  assignfile(Cs137_input,cs137filename);
  reset(Cs137_input);
  readln(Cs137_input,Cs137_num);
  setlength(Cs137_year,Cs137_num+2);
  setlength(Cs137_series,Cs137_num+2);

  for i:=1 to Cs137_num do
     begin
        readln(Cs137_input,Cs137_year[i],Cs137_series[i]);
     end;
  closefile(Cs137_input);

  year_loop_num:=floor(time_equilibrium/time_step);
  for year_loop:=1 to year_loop_num do
     begin
       t:=start_year+(year_loop-1)*time_step;

       if (t<Cs137_year[1]) OR (t>Cs137_year[Cs137_num]) then
        begin
            Rate_Cs137_input:=Cs137_input_default;
        end
      else
        begin
            for m:=1 to Cs137_num do
               begin
               if (t=Cs137_year[m]) then
                  Rate_Cs137_input:=Cs137_series[m]*time_step;    // it is amount, need to multiply the time-step
               end;
        end;

        Cs137_fallout(Rate_Cs137_input,Cs137_profile);
        tillage_mix(Cs137_profile);
        Cs137_decay(Cs137_profile);

        if unstable= FALSE then
                begin
                    Adevection_diffusion(K_coe,v_coe,Cs137_profile,unstable);
                end;
        tillage_mix(Cs137_profile);

        for i:= 1 to nrow do
          for j:=1 to ncol do
             for k:=1 to layer_num do
                begin
                   CS137[k,i,j]:=Cs137_profile[k];
                end;

     end;

 assignfile(C_file,'F:/Geoscientific model development/integrate_model\Cs_profile4.txt');
  rewrite(C_file);
  for i:=1 to layer_num do
     begin
        writeln(C_file,i,char(9), Cs137_profile[i]);
     end;
  closefile(C_file);


 end;

procedure Evolution_erosion(ero_rate: double;var Profile: vector_single);
 var
  delta_h: double;   // unit cm
  new_profile:array of single;
  profile_length: integer;
  erosion_layer: integer;
  i : integer;
begin
  profile_length:=length(Profile);
  setlength(new_profile,profile_length);
  erosion_layer:= floor(ero_rate*100/depth_interval); // multiply 100 to convert from m to cm
  delta_h:=ero_rate*100-erosion_layer*depth_interval; // convert m to cm

for i:= 1 to (layer_num-erosion_layer-1) do
  begin
      new_profile[i]:=(depth_interval-delta_h)/depth_interval*Profile[erosion_layer+i]+delta_h/depth_interval*Profile[erosion_layer+i+1];
  end;
      new_profile[layer_num-erosion_layer]:=Profile[layer_num];
  if erosion_layer>0 then
     for i:= layer_num-erosion_layer+1 to layer_num do
  begin
      new_profile[i]:=Profile[layer_num];
  end;
  for i:= 1 to layer_num do
    begin
         profile[i]:=new_profile[i];
    end;

end;

procedure Evolution_deposition(depo_rate: double; content:single; var Profile: vector_single);
 var
  delta_h:double;
  new_profile: array of single;
  profile_length: integer;
  deposition_layer: integer;
  i: integer;
begin
  profile_length:=length(Profile);
  setlength(new_profile,profile_length);

  deposition_layer:=floor(depo_rate*100/depth_interval); // mind the sign of deposition rate
  delta_h:=depo_rate*100-deposition_layer*depth_interval;

        if deposition_layer>0 then
          begin
             for i:= 1 to deposition_layer do
                new_profile[i]:=content;
          end;

        new_profile[deposition_layer+1]:=delta_h/depth_interval*content+(depth_interval-delta_h)/depth_interval*Profile[1];

        for i:=deposition_layer+2 to layer_num do
           begin
              new_profile[i]:=delta_h/depth_interval*Profile[i-1-deposition_layer]+(depth_interval-delta_h)/depth_interval*Profile[i-deposition_layer];
           end;

         for i:=1 to layer_num do
            begin
              profile[i]:=new_profile[i];
            end;

end;
Function mineralization_extrapolation:vector_single;
  var
   i: integer;
   r_vertical: array of single;
   ave_depth_layer: single;
   r_exp_cm: single;
begin
  setlength(r_vertical,layer_num+2);
  r_exp_cm:=r_exp/100; // to convert the unit of r_exp from m-1 to cm-1
  for i:=1 to layer_num do
      begin
          ave_depth_layer:=(i-0.5)*depth_interval;
          r_vertical[i]:=r0*exp(-r_exp_cm*ave_depth_layer);
      end;
   mineralization_extrapolation:=r_vertical;
  end;

Function input_allocation:vector_single;
 var
   i: integer;
   Cin_vertical, Cin_layer_relative: array of single;
   total_Cin_layer_relative:single;
   i_exp_cm: single;
   ave_depth_layer: single;
begin
   setlength(Cin_vertical,layer_num+2);
   setlength(Cin_layer_relative,layer_num+2);
   i_exp_cm:=i_exp/100;

   total_Cin_layer_relative:=0;

   for i:=1 to layer_num do
      begin
        ave_depth_layer:=(i-0.5)*depth_interval;
        Cin_layer_relative[i]:=exp(-i_exp_cm*ave_depth_layer);
        total_Cin_layer_relative:=total_Cin_layer_relative+Cin_layer_relative[i];
      end;

   for i:=1 to layer_num do
       begin
          Cin_vertical[i]:=C_input*Cin_layer_relative[i]/total_Cin_layer_relative;
          Cin_vertical[i]:=Cin_vertical[i]*100*100*1000/depth_interval/10000/BD;        // convert the input unit from  Mg C ha-1 yr-1 to % of a layer one year
       end;

   input_allocation:=Cin_vertical;

end;

Function input_allocation2:vector_single;
 var
   i: integer;
   Cin_vertical, Cin_layer_relative: array of single;
   total_Cin_layer_relative:single;
   i_exp_cm: single;
   ave_depth_layer: single;
   temp_Cinput:single;
begin
   setlength(Cin_vertical,layer_num+2);
   setlength(Cin_layer_relative,layer_num+2);
   i_exp_cm:=i_exp/100;

   total_Cin_layer_relative:=0;

   for i:=1 to layer_num do
      begin
        ave_depth_layer:=(i-0.5)*depth_interval;
        Cin_layer_relative[i]:=exp(-i_exp_cm*ave_depth_layer);
        total_Cin_layer_relative:=total_Cin_layer_relative+Cin_layer_relative[i];
      end;

   for i:=1 to layer_num do
       begin
          Cin_vertical[i]:=C_input*Cin_layer_relative[i]/total_Cin_layer_relative;
          Cin_vertical[i]:=Cin_vertical[i]*100*100*1000/depth_interval/10000/BD;        // convert the input unit from  Mg C ha-1 yr-1 to % of a layer one year
       end;

   input_allocation2:=Cin_vertical;

   temp_Cinput:=C_input2*100*100*1000/depth_interval/10000/BD;  //convert the input unit from  Mg C ha-1 yr-1 to % of a layer one year
   input_allocation2[1]:=input_allocation[1]+temp_Cinput;

end;

Procedure Carbon_Cycling(k1,k2,k3,hAS,hAP,hSP : single;Cin,r: vector_single;var A,S,P: vector_single);
 var
  i: integer;
  temp_A, temp_S, temp_P: array of single;
  Ass, Sss: array of single;
  //h_AS,h_AP,h_SP: single; // should it be a problem to use these variable with the same name as global variables in the procedure?
  //k1,k2,k3:single;        // should it be a problem to use these variable with the same name as global variables in the procedure?
begin
   setlength(temp_A,length(A));
   setlength(temp_S,length(S));
   setlength(temp_P,length(P));
   setlength(Ass,length(A));
   setlength(Sss,length(S));

   for i:=1 to layer_num do
      begin
         temp_A[i]:=A[i];
         temp_S[i]:=S[i];
         temp_P[i]:=P[i];
         Ass[i]:=Cin[i]/(r[i]*k1);
         Sss[i]:=hAS*Cin[i]/(r[i]*k2);
      end;

   for i:=1 to layer_num do
      begin
        A[i]:=Ass[i]+(temp_A[i]-Ass[i])*exp(-k1*r[i]);
        S[i]:=Sss[i]+(temp_S[i]-Sss[i]-hAS*(k1*r[i]*temp_A[i]-Cin[i])/(r[i]*(k2-k1)))*exp(-k2*r[i])+
                    (hAS*(k1*r[i]*temp_A[i]-Cin[i])/(r[i]*(k2-k1)))*exp(-k1*r[i]);
        P[i]:=(hAP*k1*r[i]*(Cin[i]/k1/r[i]+(temp_A[i]-Cin[i]/k1/r[i])*exp(-k1*r[i]))+
                    hSP*k2*r[i]*(hAS*k1*(Cin[i]/k1/r[i]+(temp_A[i]-Cin[i]/k1/r[i])*exp(-k1*r[i]))/k2+
                    (temp_S[i]-hAS*k1*(Cin[i]/k1/r[i]+(temp_A[i]-Cin[i]/k1/r[i])*exp(-k1*r[i]))/k2)*exp(-k2*r[i])))/k3/r[i]+
                    (temp_P[i]-(hAP*k1*r[i]*(Cin[i]/k1/r[i]+(temp_A[i]-Cin[i]/k1/r[i])*exp(-k1*r[i]))+
                    hSP*k2*r[i]*(hAS*k1*(Cin[i]/k1/r[i]+(temp_A[i]-Cin[i]/k1/r[i])*exp(-k1*r[i]))/k2+
                    (temp_S[i]-hAS*k1*(Cin[i]/k1/r[i]+(temp_A[i]-Cin[i]/k1/r[i])*exp(-k1*r[i]))/k2)*exp(-k2*r[i])))/k3/r[i])*exp(-k3*r[i]);

      end;

end;
procedure tillage_mix (var profile: vector_single);
var
   i: integer;
   tillage_layer : integer;
   sum,ave: single;
 begin
   tillage_layer:=round(tillage_depth/depth_interval);
   sum:=0;

   for i:= 1 to tillage_layer do
      begin
        sum:=sum+profile[i];
      end;
   ave:=sum/tillage_layer;

   for i:=1 to tillage_layer do
      begin
         profile[i]:=ave;
      end;
 end;

Procedure C14_decay(var profile:vector_single);
var
 half_life, i :integer;
 decay_rate: double;
 begin
   half_life:=5730;
  decay_rate:=0.99987905;
  //decay_rate:=exp(ln(2)/half_life);

  for i:=1 to layer_num do
     begin
       profile[i]:=profile[i]*power(decay_rate,time_step);
     end;

 end;

Procedure Cs137_decay(var profile:vector_single);
var
 half_life, i :integer;
 decay_rate: double;
 begin

  decay_rate:=0.977287193;
  for i:=1 to layer_num do
     begin
       profile[i]:=profile[i]*power(decay_rate,time_step);
     end;

 end;
Procedure Cs137_fallout(fallout_rate:single;var profile:vector_single);

begin
   profile[1]:=profile[1]+fallout_rate*(100/depth_interval)/BD;
end;

Function deltaC13_to_ratio(deltaC13:single):single;
begin
    deltaC13_to_ratio:=(deltaC13/1000+1)*PDB;
 end;

Function ratio_to_deltaC13(ratio:single):single;
begin
    ratio_to_deltaC13:=(ratio/PDB-1)*1000;
end;

Function DeltaC14_to_ratio(DeltaC14,deltaC13:single):single;
var
  C14C12_ratio_SN:single;
  C14C12_ratio_reference:single;
 begin
    C14C12_ratio_reference:=1.176/1E12;
    C14C12_ratio_SN:=C14C12_ratio_reference*(DeltaC14/1000+1);
    DeltaC14_to_ratio:=C14C12_ratio_SN/(1-2*(25+deltaC13)/1000);
 end;

Function ratio_to_DeltaC14(ratio,deltaC13:single):single;
 var
  C14C12_ratio_SN:single;
  C14C12_ratio_reference:single;

begin
   C14C12_ratio_reference:=1.176/1E12;
   C14C12_ratio_SN:=ratio*(1-2*(25+deltaC13)/1000);
   ratio_to_DeltaC14:=(C14C12_ratio_SN/C14C12_ratio_reference-1)*1000;

end;

Procedure Adevection_diffusion(K,v:vector_single;var C:vector_single;unstable:boolean);

// C: input concentration, z: depth vector with grid depth coordinates (positive),
// v and z should be of equal length, dz, dt : depth and time time step size
//tmax: time under consideration, K, v: dif + addv coefficients, also vectors
var

C_temp: array of array of single;
i,N: integer;
dt,dz: integer;
vz,Kz: array of single;
dzdub,dzsq,v_z,K_z,depth_1d,depth_2d,time_1D: single;
sum_C1,sum_C2,ratio: single;
begin
 dt:=1; // normalize dt to be 1, the values of K and v are adjusted based on time_step
 dz:=depth_interval;

 Setlength(C_temp,layer_num+5);
 for i:=1 to layer_num+4 do
    begin
      Setlength(C_temp[i],4);
      end;
  Setlength(vz,layer_num+4);
  Setlength(Kz,layer_num+4);

  for i:=1 to layer_num do
     begin
         C_temp[i+2,1]:=C[i];
         vz[i+2]:=v[i];
         Kz[i+2]:=K[i];
       end;
  C_temp[layer_num+3,1]:=C_temp[layer_num+2,1];
  vz[1]:=vz[3];  vz[2]:=vz[3]; vz[layer_num+3]:=vz[layer_num+2];
  Kz[1]:=Kz[3];  Kz[2]:=Kz[3]; Kz[layer_num+3]:=Kz[layer_num+2];

  N:=layer_num+3;
  dzdub:=2*dz;
  dzsq:=power(dz,2);

  for i:=2 to N-1 do
     begin
       v_z:=(vz[i+1]-vz[i-1])/dzdub;
       K_z:=(Kz[i+1]-Kz[i-1])/dzdub;
       depth_1d:=(C_temp[i+1,1]-C_temp[i-1,1])/dzdub;
       depth_2d:=(C_temp[i+1,1]-2*C_temp[i,1]+C_temp[i-1,1])/dzsq;
       time_1D:=Kz[i]*depth_2d+K_z*depth_1d-(vz[i]*depth_1d+C_temp[i,1]*v_z);
       C_temp[i,2]:=time_1D*dt+C_temp[i,1];
     end;
   C_temp[N,2]:=C_temp[N-1,2];
   C_temp[3,2]:=C_temp[3,2]+C_temp[2,2];
   C_temp[2,2]:=0;


 for i:=1 to layer_num+3 do
    begin
      if C_temp[i,2]<0 then
         unstable:=TRUE;
      end;

 sum_C1:=0;
for i:=1 to layer_num do
   sum_C1:=sum_C1+C[i];

sum_C2:=0;
for i:=2 to layer_num+2 do
   sum_C2:=sum_C2+C_temp[i,2];

 ratio:=sum_C1/sum_C2;
 for i:=3 to layer_num+3 do
    begin
       C_temp[i,2]:=C_temp[i,2]*ratio;
      end;
 for i:=1 to layer_num do
    begin
      C[i]:=C_temp[i+2,2];
    end;

 end;

Function K_coefficient:vector_single;
var
i: integer;

begin
 setlength(K_coefficient,layer_num+2);

 for i:=1 to layer_num do
       K_coefficient[i]:=K0*exp(-Kfzp*(i-0.5)*depth_interval);
end;

Function v_coefficient:vector_single;
var
i: integer;

begin
 setlength(v_coefficient,layer_num+2);

 for i:=1 to layer_num do
       v_coefficient[i]:=v0*exp(-vfzp*(i-0.5)*depth_interval);
end;

Function ER_erosion(waterero:single):single;
begin
 ER_erosion:=a_erero*exp(b_erero*waterero)+1;
end;

Function ER_deposition(waterero:single):single;
begin
  ER_deposition:=-0.5*exp(b_erdepo*waterero)+1;
end;

end.

