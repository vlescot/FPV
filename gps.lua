-- à renommer en un petit nom avec extension LUA (ex: gps.lua)
-- à placer dans le répertoire /SCRIPTS/FUNCTIONS/ de la radio
-- Aller dans LOGICAL SWITCHES et mettre par exemple _a>x Stats 0 -- -- 0.5s_ 
-- Donc lorsque le GPS à 1 satellite ou plus, il rafraichit les données toutes les 0.5 secondes, mais vous pouvez mettre ce qu’il vous semble le mieux.
-- Aller dans SPECIAL FUNCTIONS _L04 Lua Script nom-du-script_ (L04 est à changer selon le nom de votre LOGICAL SWITCH). 


local LaAd = "N/A" --latitudePilot en degrés
local LaAr -- idem en radians
local LoAd = "N/A" --longitudePilot en degrés
local LoAr -- idem en radians
local LaBd = "N/A" --latitudeRacer en degrés
local LaBr -- idem en radians
local LoBd = "N/A" --longitudeRacer en degrés
local LoBr -- idem en radians
local CoordOk = false -- indique que les coordonnées GPS sont présentes et correctes et donc, que le racer est en bon ordre de vol, avec transmission de données télémétriques
local ACTd --angle centre terrestre en degrés
local ACTr -- idem en radians
local Dist = "N/A" --distance entre A et B, en mètres
local DistT = "N/A" -- Dist + commentaires
local Altitude = "N/A" --altitude relative au pilot en m
local nbSats = "N/A" --nbre de satellites
local Capd = "N/A" --cap en degrés
local Capr -- idem en radians
local CapNWSE = "N/A"
local TabCapsNWSE={"N","NNW","NW","WNW","W","WSW","SW","SSW","S","SSE","SE","ESE","E","ENE","NE","NNE","N"} -- CapNWSE
local TabCapsDeg={349,326,304,281,259,236,214,191,169,146,124,101,79,56,34,11,0} -- Capd min correspondant
local gpsId
local gpsTable
local var1


local function init() -- is  called  once  when  model  is  loaded

  -- Récupération de l'identifiant du capteur GPS
  local fieldinfo = getFieldInfo("GPS")
  gpsId = fieldinfo['id']

end


local function run(event) 

  -- Lecture des données GPS
  nbSats = getValue("Sats")
  gpsTable = getValue(gpsId)
  if (type(gpsTable) == "table") then
    LaAd = gpsTable["pilot-lat"]
    LoAd = gpsTable["pilot-lon"]
    LaBd = gpsTable["lat"]
    LoBd = gpsTable["lon"]
    if LaAd ~= nil and LaAd ~= 1 and LoAd ~= nil and LoAd ~= 1 and LaBd ~= nil and LaBd ~= 1 and LoBd ~= nil and LoBd ~= 1 then
    -- cas de valeurs = 1 : constaté en live, décrochage de la réception GPS ? A filtrer donc vu qu'on vole rarement au-dessus de l'Atlantique dans le Golfe de Guinée :)
      CoordOk = true
    else
      CoordOk = false
    end
  else
    CoordOk = false
  end


  if CoordOk then
    LaAr = math.rad(LaAd)
    LoAr = math.rad(LoAd)
    LaBr = math.rad(LaBd)
    LoBr = math.rad(LoBd)
    -- Détermination du cap en degrés
    Capr = math.atan(math.cos(LaBr)* math.sin(LoBr-LoAr)/(math.cos(LaAr) * math.sin(LaBr)-math.sin(LaAr)*math.cos(LaBr)*math.cos(LoBr-LoAr)))
    Capd = math.floor(math.deg(Capr)) -- avant correction 180° éventuelle
    -- correction éventuelle
    if LaAr>LaBr then
      Capd=Capd+180
    elseif LoAr<LoBr then
      Capd = Capd
    else
      Capd = Capd + 360
    end
    -- détermination du cap en NWSE
    for i=1,17 do
      if Capd >= TabCapsDeg[i] then
        CapNWSE = TabCapsNWSE[i]
        break
      end   
    end

    -- détermination de la distance  
    ACTr=math.acos(math.sin(LaAr)*math.sin(LaBr)+math.cos(LaAr)*math.cos(LaBr)*math.cos(LoBr-LoAr))
    ACTd=math.deg(ACTr)
    Dist=math.floor(1852*60*ACTd)

    -- calcul altitude
    var1 = getValue("Alt")
    if var1 ~= 0 then -- si pas de retour de télémétrie, getValue retourne une valeur nulle
      Altitude = getValue("Alt")
    end

    -- date de la radio
    local D = getDateTime();    
    local date = D.year.."-"..D.mon.."-"..D.day.." "..D.hour.."h"..D.min.."m"..D.sec.."s"

    -- ecriture du fichier    
    local f = io.open("/LOGS/gps_infos.txt", "w+")

    io.write(f, date, "\r\n\r\n")
    io.write(f, "GPS : "..nbSats.." SATS\r\n")
    io.write(f, "LAT : "..LaBd.."\r\n")
    io.write(f, "LON : "..LoBd.."\r\n")
    io.write(f, "DIST : "..Dist.." m".."\r\n")
    if Altitude ~= "N/A" then
      io.write(f, "ALT : "..Altitude.." m\r\n")
    end

    io.close(f)
  else
    -- on en fait surtout rien sinon ecrasement des données en cas de perte de la télémétrie    
  end

end
  
return { init=init, background=background, run=run }
