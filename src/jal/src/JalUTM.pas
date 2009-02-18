(****************************************************************************
 * WANT - A build management tool.                                          *
 * Copyright (c) 1995-2003 Juancarlo Anez, Caracas, Venezuela.              *
 * All rights reserved.                                                     *
 *                                                                          *
 * This library is free software; you can redistribute it and/or            *
 * modify it under the terms of the GNU Lesser General Public               *
 * License as published by the Free Software Foundation; either             *
 * version 2.1 of the License, or (at your option) any later version.       *
 *                                                                          *
 * This library is distributed in the hope that it will be useful,          *
 * but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU        *
 * Lesser General Public License for more details.                          *
 *                                                                          *
 * You should have received a copy of the GNU Lesser General Public         *
 * License along with this library; if not, write to the Free Software      *
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA *
 ****************************************************************************)
{
    @brief 

    @author Juancarlo Añez
}

{%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
{ Original code in C++ written by:             }
{                                              }
{   Chuck Gantz- chuck.gantz@globalstar.com    }
{                                              }
{ Thanks Chuck!                                             }
{%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

{#(@)$Id: JalUTM.pas 706 2003-05-14 22:13:46Z hippoman $}
unit JalUTM;
interface
uses
  SysUtils,
  Math,

  JalMath,
  JalGeometry;

const
  FOURTHPI = PI / 4;

type
  TReferenceEllipsoidId =
  (
    ellipsoid_Airy,
    ellipsoid_Australian_National,
    ellipsoid_Bessel_1841,
    ellipsoid_Bessel_1841_Nambia,
    ellipsoid_Clarke_1866,
    ellipsoid_Clarke_1880,
    ellipsoid_Everest,
    ellipsoid_Fischer_1960_Mercury,
    ellipsoid_Fischer_1968,
    ellipsoid_GRS_1967,
    ellipsoid_GRS_1980,
    ellipsoid_Helmert_1906,
    ellipsoid_Hough,
    ellipsoid_International,
    ellipsoid_Krassovsky,
    ellipsoid_Modified_Airy,
    ellipsoid_Modified_Everest,
    ellipsoid_Modified_Fischer_1960,
    ellipsoid_South_American_1969,
    ellipsoid_WGS_60,
    ellipsoid_WGS_66,
    ellipsoid_WGS_72,
    ellipsoid_WGS_84
  );

type
  TEllipsoid = record
    name                :string;
    EquatorialRadius    :Double;
    EccentricitySquared :Double;
  end;

  TUTMCoord = record
    Northing :Double;
    Easting  :Double;
    Zone     :string;
  end;

  TUTMLLConverter = class
    ellipsoidId :TReferenceEllipsoidId;

    constructor Create;

    function LLtoUTM(Lat, Long :Double) :TUTMCoord;

    function UTMtoLL(const Northing, Easting :Double; const Zone :string):TVector; overload;
    function UTMtoLL(const coord :TUTMCoord):TVector; overload;

    function UTMLetterDesignator(Lat :double):char;
  end;


const
  REFERENCE_ELLIPSOID : array [TReferenceEllipsoidId] of TEllipsoid =
  (
    ( name: 'Airy';
      EquatorialRadius:  6377563;
      EccentricitySquared:0.00667054
    ),
    ( name: 'Australian National';
      EquatorialRadius:  6378160;
      EccentricitySquared:0.006694542
    ),
    ( name: 'Bessel 1841';
      EquatorialRadius:  6377397;
      EccentricitySquared:0.006674372
    ),
    ( name: 'Bessel 1841 (Nambia)';
      EquatorialRadius:  6377484;
      EccentricitySquared:0.006674372
    ),
    ( name: 'Clarke 1866';
      EquatorialRadius:  6378206;
      EccentricitySquared:0.006768658
    ),
    ( name: 'Clarke 1880';
      EquatorialRadius:  6378249;
      EccentricitySquared:0.006803511
    ),
    ( name: 'Everest';
      EquatorialRadius:  6377276;
      EccentricitySquared:0.006637847
    ),
    ( name: 'Fischer 1960 (Mercury)';
      EquatorialRadius:  6378166;
      EccentricitySquared:0.006693422
    ),
    ( name: 'Fischer 1968';
      EquatorialRadius:  6378150;
      EccentricitySquared:0.006693422
    ),
    ( name: 'GRS 1967';
      EquatorialRadius:  6378160;
      EccentricitySquared:0.006694605
    ),
    ( name: 'GRS 1980';
      EquatorialRadius:  6378137;
      EccentricitySquared:0.00669438
    ),
    ( name: 'Helmert 1906';
      EquatorialRadius:  6378200;
      EccentricitySquared:0.006693422
    ),
    ( name: 'Hough';
      EquatorialRadius:  6378270;
      EccentricitySquared:0.00672267
    ),
    ( name: 'International';
      EquatorialRadius:  6378388;
      EccentricitySquared:0.00672267
    ),
    ( name: 'Krassovsky';
      EquatorialRadius:  6378245;
      EccentricitySquared:0.006693422
    ),
    ( name: 'Modified Airy';
      EquatorialRadius:  6377340;
      EccentricitySquared:0.00667054
    ),
    ( name: 'Modified Everest';
      EquatorialRadius:  6377304;
      EccentricitySquared:0.006637847
    ),
    ( name: 'Modified Fischer 1960';
      EquatorialRadius:  6378155;
      EccentricitySquared:0.006693422
    ),
    ( name: 'South American 1969';
      EquatorialRadius:  6378160;
      EccentricitySquared:0.006694542
    ),
    ( name: 'WGS 60';
      EquatorialRadius:  6378165;
      EccentricitySquared:0.006693422
    ),
    ( name: 'WGS 66';
      EquatorialRadius:  6378145;
      EccentricitySquared:0.006694542
    ),
    ( name: 'WGS-72';
      EquatorialRadius:  6378135;
      EccentricitySquared:0.006694318
    ),
    ( name: 'WGS-84';
      EquatorialRadius:  6378137;
      EccentricitySquared:0.00669438
    )
);

implementation
{ TUTMLLConverter }

constructor TUTMLLConverter.Create;
begin
  inherited Create;
  ellipsoidId := ellipsoid_WGS_84;
end;

(**
  * converts lat/long to UTM coords.  Equations from USGS Bulletin 1532
  * East Longitudes are positive, West longitudes are negative.
  * North latitudes are positive, South latitudes are negative
  * Lat and Long are in decimal degrees
  * Written by Chuck Gantz- chuck.gantz@globalstar.com
  *)
function TUTMLLConverter.LLtoUTM(Lat, Long: Double): TUTMCoord;
var
  ecradius        :Double;
  ecc2, k0        :Double;
  LongOrigin      :Double;
  EccPrimeSquared :Double;
  N, T, C, A, M   :Double;
  LatRad          :Double;
  LongRad         :Double;
  LongOriginRad   :Double;
  ZoneNumber      :Integer;
begin
  with REFERENCE_ELLIPSOID[self.ellipsoidId] do
  begin
    ecradius    := EquatorialRadius;
    ecc2        := eccentricitySquared;
  end;

  k0          := 0.9996;

  //Make sure the longitude is between -180.00 .. 179.9
  Long := (Long+180)-Int((Long+180)/360)*360-180; // -180.00 .. 179.9;

  LatRad  := DegToRad(Lat);
  LongRad := DegToRad(Long);

  ZoneNumber := Trunc((Long + 180)/6) + 1;

  if(Lat >= 56.0) and (Lat < 64.0) and (Long >= 3.0) and (Long < 12.0) then
    ZoneNumber := 32;

  // Special zones for Svalbard, Switzerland
  if (Lat >= 72.0) and (Lat < 84.0) then
  begin
    if      (Long >= 0.0)  and (Long <  9.0) then
      ZoneNumber := 31
    else if (Long >= 9.00) and (Long < 21.0) then
      ZoneNumber := 33
    else if (Long >= 21.0) and (Long < 33.0) then
      ZoneNumber := 35
    else if (Long >= 33.0) and (Long < 42.0) then
      ZoneNumber := 37
  end;

  LongOrigin    := (ZoneNumber - 1)*6 - 180 + 3;  //+3 puts origin in middle of zone
  LongOriginRad := DegToRad(LongOrigin);

  //compute the UTM Zone from the latitude and longitude
  Result.Zone := Format('%d%s', [ZoneNumber, UTMLetterDesignator(Lat)]);

  eccPrimeSquared := (ecc2)/(1-ecc2);

  N := ecradius/sqrt(1-ecc2*sin(LatRad)*sin(LatRad));
  T := tan(LatRad)*tan(LatRad);
  C := eccPrimeSquared*cos(LatRad)*cos(LatRad);
  A := cos(LatRad)*(LongRad-LongOriginRad);

  M := a*((1  - ecc2/4    - 3*ecc2*ecc2/64  - 5*ecc2*ecc2*ecc2/256)*LatRad
        - (3*ecc2/8  + 3*ecc2*ecc2/32  + 45*ecc2*ecc2*ecc2/1024)*sin(2*LatRad)
                  + (15*ecc2*ecc2/256 + 45*ecc2*ecc2*ecc2/1024)*sin(4*LatRad) 
                  - (35*ecc2*ecc2*ecc2/3072)*sin(6*LatRad));
  
  Result.Easting := (k0*N*(A+(1-T+C)*A*A*A/6
          + (5-18*T+T*T+72*C-58*eccPrimeSquared)*A*A*A*A*A/120)
          + 500000.0);

  Result.Northing := (k0*(M+N*tan(LatRad)*(A*A/2+(5-T+9*C+4*C*C)*A*A*A*A/24
         + (61-58*T+T*T+600*C-330*eccPrimeSquared)*A*A*A*A*A*A/720)));
  if Lat < 0 then
    with Result do
      Northing :=  Northing + 10000000.0; //10000000 meter offset for southern hemisphere
end;

function TUTMLLConverter.UTMtoLL(const coord: TUTMCoord): TVector;
begin
  with coord do
    Result := UTMtoLL(Northing, Easting, Zone);
end;

(**
  * converts UTM coords to lat/long.  Equations from USGS Bulletin 1532
  * East Longitudes are positive, West longitudes are negative.
  * North latitudes are positive, South latitudes are negative
  * Lat and Long are in decimal degrees.
  * Written by Chuck Gantz- chuck.gantz@globalstar.com
  *)
function TUTMLLConverter.UTMtoLL(const Northing, Easting: Double; const Zone: string): TVector;
var
  k0, ecradius     :Double;
  eccSquared       :Double;
  eccPrimeSquared  :Double;
  e1, N1, T1, C1,
  R1, D, M         :Double;
  LongOrigin       :Double;
  mu, phiRad       :Double;
  x, y             :Double;
  Lat, Long        :Double;
  ZoneNumber       :Integer;
  ZoneLetter       :char;
begin
  with REFERENCE_ELLIPSOID[self.ellipsoidId] do
  begin
    ecradius   := EquatorialRadius;
    eccSquared := eccentricitySquared;
  end;

  k0         := 0.9996;
  e1         := (1-sqrt(1-eccSquared))/(1+sqrt(1-eccSquared));

  x := Easting - 500000.0; //remove 500,000 meter offset for longitude
  y := Northing;

  ZoneNumber := StrToIntDef(copy(Zone, 1, Length(Zone)-1), 10);
  if Length(Zone) = 0 then
    ZoneLetter := 'N'
  else
    ZoneLetter := Zone[Length(Zone)];
  if (Ord(ZoneLetter) - Ord('N')) < 0 then
  begin
    //point is in southern hemisphere
    y := y - 10000000.0;//remove 10,000,000 meter offset used for southern hemisphere
  end;

  LongOrigin := (ZoneNumber - 1)*6 - 180 + 3;  //+3 puts origin in middle of zone

  eccPrimeSquared := (eccSquared)/(1-eccSquared);

  M  := y / k0;
  mu := M/(ecradius*(1-eccSquared/4-3*eccSquared*eccSquared/64-5*eccSquared*eccSquared*eccSquared/256));

  phiRad := mu  + (3*e1/2-27*e1*e1*e1/32)*sin(2*mu)
        + (21*e1*e1/16-55*e1*e1*e1*e1/32)*sin(4*mu)
        +(151*e1*e1*e1/96)*sin(6*mu);
  //phi    := RadToDeg(phiRad);

  N1 := ecradius/sqrt(1-eccSquared*sin(phiRad)*sin(phiRad));
  T1 := tan(phiRad)*tan(phiRad);
  C1 := eccPrimeSquared*cos(phiRad)*cos(phiRad);
  R1 := ecradius*(1-eccSquared)/Power(1-eccSquared*sin(phiRad)*sin(phiRad), 1.5);
  D := x/(N1*k0);

  Lat := phiRad - (N1*tan(phiRad)/R1)*(D*D/2-(5+3*T1+10*C1-4*C1*C1-9*eccPrimeSquared)*D*D*D*D/24
          +(61+90*T1+298*C1+45*T1*T1-252*eccPrimeSquared-3*C1*C1)*D*D*D*D*D*D/720);
  Lat := RadToDeg(Lat);

  Long := (D-(1+2*T1+C1)*D*D*D/6+(5-2*C1+28*T1-3*C1*C1+8*eccPrimeSquared+24*T1*T1)
          *D*D*D*D*D/120)/cos(phiRad);
  Long := LongOrigin + RadToDeg(Long);

  with Result do
  begin
    X := Long;
    Y := Lat;
    Z := 0;
  end;
end;

(**
  * This routine determines the correct UTM letter designator for the given latitude
  * returns 'Z' if latitude is outside the UTM limits of 84N to 80S
  * Written by Chuck Gantz- chuck.gantz@globalstar.com
  *)
function TUTMLLConverter.UTMLetterDesignator(Lat: double): char;
begin
  if (84 >= Lat) and (Lat >= 72) then
    Result := 'X'
  else if (72 > Lat) and (Lat >= 64) then
    Result := 'W'
  else if (64 > Lat) and (Lat >= 56) then
    Result := 'V'
  else if (56 > Lat) and (Lat >= 48) then
    Result := 'U'
  else if (48 > Lat) and (Lat >= 40) then
    Result := 'T'
  else if (40 > Lat) and (Lat >= 32) then
    Result := 'S'
  else if (32 > Lat) and (Lat >= 24) then
    Result := 'R'
  else if (24 > Lat) and (Lat >= 16) then
    Result := 'Q'
  else if (16 > Lat) and (Lat >= 8) then
    Result := 'P'
  else if ( 8 > Lat) and (Lat >= 0) then
    Result := 'N'
  else if ( 0 > Lat) and (Lat >= -8) then
    Result := 'M'
  else if (-8> Lat) and (Lat >= -16) then 
    Result := 'L'
  else if (-16 > Lat) and (Lat >= -24) then 
    Result := 'K'
  else if (-24 > Lat) and (Lat >= -32) then 
    Result := 'J'
  else if (-32 > Lat) and (Lat >= -40) then 
    Result := 'H'
  else if (-40 > Lat) and (Lat >= -48) then 
    Result := 'G'
  else if (-48 > Lat) and (Lat >= -56) then
    Result := 'F'
  else if (-56 > Lat) and (Lat >= -64) then 
    Result := 'E'
  else if (-64 > Lat) and (Lat >= -72) then 
    Result := 'D'
  else if (-72 > Lat) and (Lat >= -80) then
    Result := 'C'
  else
    //This is here as an error flag
    // to show that the Latitude is outside the UTM limits
    Result := 'Z';
end;

end.
