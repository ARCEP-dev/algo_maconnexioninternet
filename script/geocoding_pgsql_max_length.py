#!/usr/bin/python3
from sys import argv, exit
from time import time, sleep
from requests import get
from json import loads, dumps
import _pg
from math import radians, sin, cos, acos, atan2, sqrt

#python geocoding_pgsql.py db_ip db_port db_name db_user db_password api_url schema table score_min parall_workers parall_id

beginTime = time()

geocode_count = 0
score_min = 0.60
total = 0
success = 0
score_sum = 0
addr_id = 0
offset = 0
addr_step = 100

verbose = True

try:
    if(len(argv) < 9):
        raise NameError("Error ! Not enough params.\r\nNeed : db_ip db_port db_name db_user db_password api_url schema table score_min parall_workers parall_id")
    db_ip = str(argv[1]);
    db_port = int(argv[2]);
    db_name = argv[3];
    db_user = argv[4];
    db_password = argv[5];
    api_url = argv[6];
    schema = argv[7];
    table = argv[8];
    if(len(argv) >= 10):
        score_min = float(argv[9]);
    if(len(argv) == 12):
        parall_workers = int(argv[10]);
        parall_id = int(argv[11]);
    else:
        parall_workers = 1;
        parall_id = 0;
except NameError as e:
    exit(e)

# Test DB connexion
try:
    db_conn = _pg.connect(db_name, db_ip, db_port, None, db_user, db_password)
except Exception as e:
    exit(e)

# Test BAN API connexion
try:
    response = get(api_url + "?q=8+bd+du+port")
    if(response.status_code > 200):
        raise NameError("API BAN error ! http_status_code=" + str(response.status_code))
except NameError as e:
    exit(e)
except:
    exit("API BAN error !")


# calcul de distance entre deux couples de coordonnées
def distance_sphere(lat_1, lon_1, lat_2, lon_2):
    radius = 6371 # km
    dlat = radians(lat_2 - lat_1)
    dlon = radians(lon_2 - lon_1)
    a = sin(dlat/2) * sin(dlat/2) + cos(radians(lat_1)) \
        * cos(radians(lat_2)) * sin(dlon/2) * sin(dlon/2)
    c = 2 * atan2(sqrt(a), sqrt(1-a))
    d = radius * c
    return int(d * 1000)


# effecture une req. sur l'API de géocodage
def geocode(api, params):
    params['autocomplete']=0
    params['q'] = params['q'].strip()
    try:
        r = get(api, params)
        j = loads(r.text)
        global geocode_count
        geocode_count += 1
        if 'features' in j and len(j['features'])>0:
            if params['limit'] == 1:
                return(j['features'][0])
            else:
                return(j['features'])
        else:
            return(None)
    except:
        print(dumps({'status':'erreur','params': params}))
        sleep(1)
        geocode(api, params)


# surcouche de géocodage avec distance limite
def geocode_max_length(api, params, maxLength):
    sel = []
    maxNote = 0.0
    minDistance = maxLength + 1
    res = geocode(api_url, params)
    if res != None:
        for x in range(len(res)):
            res[x]['properties']['distance'] = distance_sphere(params['lat'], params['lon'], res[x]['geometry']['coordinates'][1], res[x]['geometry']['coordinates'][0])
            if(res[x]['properties']['distance'] <= maxLength and res[x]['properties']['score'] >= score_min):
                sel.append(x)
                if res[x]['properties']['score'] > maxNote:
                    maxNote = res[x]['properties']['score']
                if res[x]['properties']['distance'] < minDistance:
                    minDistance = res[x]['properties']['distance']
        for y in range(len(sel)):
            if(res[sel[y]]['properties']['distance'] == minDistance and res[x]['properties']['score'] == maxNote):
                return res[sel[y]]
    return(None)


stats = {'status':'progress', 'duration':0, 'count':0, 'success':0, 'city':0, 'street':0, 'housenumber':0, 'params':{'inputData':'DB:pgsql', 'score_min':score_min}, 'perf':{'efficacity':0.0, 'score_avg':0.0, 'addrPerSecond':0.0}}

query = "SELECT count(*), MIN(id),  MAX(id) FROM " + schema + "." + table + " WHERE code_ban IS NULL AND geom IS NOT NULL AND (geocoding_failure IS False OR geocoding_failure IS NULL);"
addr_stats = db_conn.query(query).getresult()
addr_count = addr_stats[0][0]

if (addr_count == 0):
  db_conn.close()
  exit("No address to process !")

addr_first_id = addr_stats[0][1]
addr_last_id = addr_stats[0][2]
first_id = addr_first_id + int((addr_last_id - addr_first_id) / parall_workers * parall_id)
last_id = addr_first_id + int((addr_last_id - addr_first_id) / parall_workers * (parall_id + 1))

if(verbose):
    print("Nbr addr : " + str(addr_count))
    print("First id : " + str(first_id))
    print("Last id : " + str(last_id))

addr_id = first_id

update_on_success_code = "PREPARE update_on_success_code (int, varchar) AS UPDATE " + schema + "." + table + " SET code_ban = $2, geocoding_failure = False WHERE id = $1;"
update_on_success_code_geom = "PREPARE update_on_success_code_geom (int, varchar, float, float) AS UPDATE " + schema + "." + table + " SET code_ban = $2, geom = ST_setSRID(ST_Point($3, $4), 4326), geocoding_failure = False WHERE id = $1;"
update_on_fail = "PREPARE update_on_fail (int) AS UPDATE " + schema + "." + table + " SET geocoding_failure = True WHERE id = $1;"

if(schema == 'reseau_cu' and table == 'ld'):
    techno = 'cu'
    maxLength = 1500
    select_addr = "PREPARE select_addr (int) AS SELECT id, numero_voie, null::varchar AS complement_voie, null::varchar AS type_voie, nom_voie, code_insee, ST_X(ST_Transform(geom, 4326)) AS lon, ST_Y(ST_Transform(geom, 4326)) AS lat FROM " + schema + "." + table + " WHERE code_ban IS NULL AND id >= ($1)::int AND id <= ($1 + " + str(addr_step) + ")::int AND id <= " + str(last_id) + " AND geom IS NOT NULL AND (geocoding_failure IS False OR geocoding_failure IS NULL) LIMIT 1;"
elif(schema == 'reseau_fo' and table == 'imb'):
    techno = 'fo'
    maxLength = 150
    select_addr = "PREPARE select_addr (int) AS SELECT id, numero_voie, complement_voie, type_voie, nom_voie, code_insee, ST_X(ST_Transform(geom, 4326)) AS lon, ST_Y(ST_Transform(geom, 4326)) AS lat FROM " + schema + "." + table + " WHERE code_ban IS NULL AND id >= ($1)::int AND id <= ($1 + " + str(addr_step) + ")::int AND id <= " + str(last_id) + " AND geom IS NOT NULL AND (geocoding_failure IS False OR geocoding_failure IS NULL) LIMIT 1;"
elif(schema == 'reseau_coax' and table == 'adresse'):
    techno = 'coax'
    maxLength = 150
    select_addr = "PREPARE select_addr (int) AS SELECT id, numero_voie, complement AS complement_voie, type_voie, nom_voie, code_insee, ST_X(ST_Transform(geom, 4326)) AS lon, ST_Y(ST_Transform(geom, 4326)) AS lat FROM " + schema + "." + table + " WHERE code_ban IS NULL AND id >= ($1)::int AND id <= ($1 + " + str(addr_step) + ")::int AND id <= " + str(last_id) + " AND geom IS NOT NULL AND (geocoding_failure IS False OR geocoding_failure IS NULL) LIMIT 1;"
else:
    exit("No match for table " + table + " in schema " + schema + " !")


db_conn.query(select_addr)
db_conn.query(update_on_success_code)
db_conn.query(update_on_success_code_geom)
db_conn.query(update_on_fail)

while (addr_id <= last_id) :
    query = "EXECUTE select_addr(" + str(addr_id) + ");"
    addr = db_conn.query(query).getresult()

    if(len(addr) > 0):
        addr_id = addr[0][0]
        addr_numero = addr[0][1]
        addr_complement = addr[0][2]
        addr_type_voie = addr[0][3]
        addr_nom_voie = addr[0][4]
        addr_code_insee = addr[0][5]
        lat = addr[0][7]
        lon = addr[0][6]
        addr_adresse = ""
        if(addr_complement != None):
            addr_adresse += ' ' + addr_complement
        if(addr_type_voie != None):
            addr_adresse += ' ' + addr_type_voie
        if(addr_nom_voie != None):
            addr_adresse += ' ' + addr_nom_voie
        if(addr_numero != None):
            if(addr_numero > 0):
                addr_adresse = str(addr_numero) + ' ' + addr_adresse

        ban_result = geocode_max_length(api_url, {'q': addr_adresse, 'citycode': addr_code_insee, 'lat': lat, 'lon': lon, 'limit': '1'}, maxLength)

        if ban_result is None or ban_result['properties']['score'] < score_min:
            db_conn.query("EXECUTE update_on_fail(" + str(addr_id) + ");")
        else:
            score_sum += ban_result['properties']['score'] * 100
            ban_type = ban_result['properties']['type']
            house_number = ""
            if ['village','town','city','municipality','locality'].count(ban_type)>0:
                stats['city']+=1
                db_conn.query("EXECUTE update_on_fail(" + str(addr_id) + ");")
            elif ban_type == 'street':
                stats['street']+=1
                db_conn.query("EXECUTE update_on_fail(" + str(addr_id) + ");")
            elif ban_type == 'housenumber':
                success+=1
                stats['housenumber']+=1
                house_number = ban_result['properties']['housenumber']
                if (techno == 'cu' or (techno == 'fo' and (lat == type(None) or lon == type(None))) or (type == 'coax' and (lat == type(None) or lon == type(None)))):
                    db_conn.query("EXECUTE update_on_success_code_geom(" + str(addr_id) + "::int, '" + ban_result['properties']['id'] + "', " + str(ban_result['geometry']['coordinates'][0]) + ", " + str(ban_result['geometry']['coordinates'][1]) + ");")
                else:
                    db_conn.query("EXECUTE update_on_success_code(" + str(addr_id) + "::int, '" + ban_result['properties']['id'] + "');")

        total = total + 1

        if total % 100 == 0:
            stats['count'] = total
            stats['success'] = success
            stats['duration'] = int(time() - beginTime)
            if stats['duration'] > 0:
                stats['perf']['addrPerSecond'] = round(total / stats['duration'], 2)
            stats['perf']['efficacity'] = round(100*success / total, 2)
            if success > 0:
                stats['perf']['score_avg'] = round(score_sum/100 / success, 2)
            if(verbose):
                print(dumps(stats, sort_keys=True))

    elif(len(addr) == 0 and addr_id < last_id):
        addr_id = addr_id + addr_step

    # Stop if no more address
    else:
        print("No more address to process")
        break;
db_conn.close()

stats['duration'] = int(time() - beginTime)
stats['status'] = 'finish'
stats['count'] = total
stats['success'] = success
if stats['duration'] > 0:
    stats['perf']['addrPerSecond'] = round(total / stats['duration'], 2)
if total > 0:
    stats['perf']['efficacity'] = round(100*success / total, 2)
if success > 0:
    stats['perf']['score_avg'] = round(score_sum/100 / success, 2)

if(verbose):
    print('---')
    print('Statistics')
    print(dumps(stats, sort_keys=False, indent=True))
