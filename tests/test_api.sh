#!/usr/bin/env bash
# CarRental API — end-to-end endpoint test suite.
# Each check hits the real running API over HTTP and asserts the status code
# (and, where it matters, the response body).
#
# IMPORTANT: run this against a FRESH, EMPTY database. The suite creates customers
# with fixed email addresses, and Email has a unique index, so a second run against
# the same data returns 409 on those inserts and every later check that depends on
# the created ids fails in a cascade.
#
#   rm -f /tmp/carrental_test.db          # start clean
#   DatabaseProvider=Sqlite \
#   ConnectionStrings__DefaultConnection="Data Source=/tmp/carrental_test.db" \
#   ASPNETCORE_ENVIRONMENT=Development ASPNETCORE_URLS="http://127.0.0.1:5109" \
#   dotnet run --project CarRental.API    # window 1
#
#   UPLOADS_DIR=CarRental.API/wwwroot/uploads ./tests/test_api.sh   # window 2

BASE="http://127.0.0.1:5109"
PASS=0; FAIL=0
declare -a FAILURES

# ---- helpers -----------------------------------------------------------------
# req METHOD PATH [BODY] [TOKEN]  -> sets $STATUS and $BODY
req() {
  local method="$1" path="$2" body="${3:-}" token="${4:-}"
  local args=(-sS -o /tmp/_body -w '%{http_code}' -X "$method" "$BASE$path"
              -H 'Content-Type: application/json' --max-time 20)
  [ -n "$token" ] && args+=(-H "Authorization: Bearer $token")
  [ -n "$body" ] && args+=(-d "$body")
  STATUS=$(curl "${args[@]}")
  BODY=$(tr -d '\000' < /tmp/_body 2>/dev/null | head -c 2000)
}

# reqform METHOD PATH TOKEN [field=value | field=@file ...]  -> multipart/form-data
reqform() {
  local method="$1" path="$2" token="$3"; shift 3
  local args=(-sS -o /tmp/_body -w '%{http_code}' -X "$method" "$BASE$path" --max-time 30)
  [ -n "$token" ] && args+=(-H "Authorization: Bearer $token")
  local f
  for f in "$@"; do args+=(-F "$f"); done
  STATUS=$(curl "${args[@]}")
  BODY=$(tr -d '\000' < /tmp/_body 2>/dev/null | head -c 2000)
}

# check LABEL EXPECTED_STATUS
check() {
  local label="$1" expected="$2"
  if [ "$STATUS" = "$expected" ]; then
    PASS=$((PASS+1)); printf '  \033[32mPASS\033[0m  %-58s %s\n' "$label" "$STATUS"
  else
    FAIL=$((FAIL+1)); FAILURES+=("$label (expected $expected, got $STATUS): $BODY")
    printf '  \033[31mFAIL\033[0m  %-58s got %s want %s\n' "$label" "$STATUS" "$expected"
    printf '        body: %s\n' "$(echo "$BODY" | head -c 300)"
  fi
}

# assert_num LABEL JQ_PATH EXPECTED_NUMBER  (tolerant of 1050 vs 1050.00)
assert_num() {
  local label="$1" path="$2" expected="$3"
  local actual
  actual=$(python3 -c "
import json
try:
    d=json.load(open('/tmp/_body'))
    print(float(d$path))
except Exception as e:
    print('ERR:'+str(e))
")
  local ok
  ok=$(python3 -c "
try: print('1' if abs(float('$actual')-float('$expected'))<0.005 else '0')
except Exception: print('0')")
  if [ "$ok" = "1" ]; then
    PASS=$((PASS+1)); printf '  \033[32mPASS\033[0m  %-58s %s\n' "$label" "$actual"
  else
    FAIL=$((FAIL+1)); FAILURES+=("$label (expected $expected, got $actual)")
    printf '  \033[31mFAIL\033[0m  %-58s got %s want %s\n' "$label" "$actual" "$expected"
  fi
}

# assert_json LABEL JQ_PATH EXPECTED
assert_json() {
  local label="$1" path="$2" expected="$3"
  local actual
  actual=$(python3 -c "
import json,sys
try:
    d=json.load(open('/tmp/_body'))
    v=d$path
    print(json.dumps(v) if isinstance(v,(dict,list)) else v)
except Exception as e:
    print('ERR:'+str(e))
")
  if [ "$actual" = "$expected" ]; then
    PASS=$((PASS+1)); printf '  \033[32mPASS\033[0m  %-58s %s\n' "$label" "$actual"
  else
    FAIL=$((FAIL+1)); FAILURES+=("$label (expected $expected, got $actual)")
    printf '  \033[31mFAIL\033[0m  %-58s got %s want %s\n' "$label" "$actual" "$expected"
  fi
}

jqv() { python3 -c "
import json;d=json.load(open('/tmp/_body'));v=d$1
print(json.dumps(v) if isinstance(v,(dict,list)) else v)"; }

section() { printf '\n\033[1;36m══ %s\033[0m\n' "$1"; }

TOMORROW=$(date -u -d '+1 day' +%Y-%m-%d)
NEXTWEEK=$(date -u -d '+8 days' +%Y-%m-%d)
LATER=$(date -u -d '+20 days' +%Y-%m-%d)
LATER_END=$(date -u -d '+25 days' +%Y-%m-%d)
YESTERDAY=$(date -u -d '-1 day' +%Y-%m-%d)

# ---- image fixtures (used by Cars form tests) ---------------------------------
python3 - <<'PYFIX'
import zlib, struct
def png(path, w=8, h=8):
    def ch(t,d):
        c=t+d
        return struct.pack(">I",len(d))+c+struct.pack(">I",zlib.crc32(c)&0xffffffff)
    raw=b"".join(b"\x00"+bytes((30,90,200))*w for _ in range(h))
    open(path,"wb").write(b"\x89PNG\r\n\x1a\n"
        + ch(b"IHDR",struct.pack(">IIBBBBB",w,h,8,2,0,0,0))
        + ch(b"IDAT",zlib.compress(raw)) + ch(b"IEND",b""))
png("/tmp/t_car.png")
open("/tmp/t_car.jpg","wb").write(bytes.fromhex("FFD8FF")+b"\xE0\x00\x10JFIF\x00"+b"\x00"*40+b"\xFF\xD9")
open("/tmp/t_fake.png","wb").write(b"not an image at all, just text")
png("/tmp/t_mismatch.jpg")
open("/tmp/t_huge.png","wb").write(open("/tmp/t_car.png","rb").read()+b"\x00"*(6*1024*1024))
PYFIX

# ---- 0. infrastructure -------------------------------------------------------
section "0. Infrastructure"
req GET /health;                             check "GET /health" 200
req GET /swagger/v1/swagger.json;            check "Swagger JSON generated" 200
assert_json "Swagger declares Bearer scheme" "['components']['securitySchemes']['Bearer']['scheme']" "bearer"
# BUGFIX guard: the requirement used to serialise as an empty object ("security":[{}]),
# so Swagger UI never sent the Authorization header even after a correct Authorize.
assert_json "Swagger applies the Bearer requirement" "['security'][0]['Bearer']" "[]"

# ---- 1. authentication -------------------------------------------------------
section "1. Authentication (JWT)"
req POST /api/auth/login '{"username":"admin","password":"WRONG"}'
check "Login with wrong password -> 401" 401
req POST /api/auth/login '{"username":"admin","password":""}'
check "Login with empty password -> 400 (validation)" 400
req POST /api/auth/login '{"username":"admin","password":"Admin@12345"}'
check "Login with correct credentials -> 200" 200
TOKEN=$(jqv "['token']")
[ -n "$TOKEN" ] && [ "$TOKEN" != "null" ] && { PASS=$((PASS+1)); echo -e "  \033[32mPASS\033[0m  Token issued"; } \
  || { FAIL=$((FAIL+1)); FAILURES+=("no token issued"); echo -e "  \033[31mFAIL\033[0m  Token issued"; }

req GET /api/auth/me "" "$TOKEN";            check "GET /api/auth/me with token -> 200" 200
req GET /api/auth/me;                        check "GET /api/auth/me without token -> 401" 401

# ---- 2. authorization enforcement -------------------------------------------
section "2. Authorization enforcement"
req GET /api/cars;                           check "Cars list is public (anonymous)" 200
reqform POST /api/cars "" model=X brand=Y pricePerDay=10
check "Create car without token -> 401" 401
req GET /api/customers;                      check "Customers require token -> 401" 401

# ---- 3. cars CRUD ------------------------------------------------------------
section "3. Cars CRUD + validation"
reqform POST /api/cars "$TOKEN" "model=Camry 2024" brand=Toyota pricePerDay=150.00 image=@/tmp/t_car.png
check "Create car + photo in ONE request -> 201" 201
CAR1=$(jqv "['id']")
assert_json "New car status is Available"    "['status']" "Available"
IMG_CAR1=$(jqv "['imageUrl']")
case "$IMG_CAR1" in /uploads/*.png)
  PASS=$((PASS+1)); echo -e "  \033[32mPASS\033[0m  Photo stored, imageUrl auto-filled ($IMG_CAR1)";;
*) FAIL=$((FAIL+1)); FAILURES+=("imageUrl not set on create: $IMG_CAR1")
   echo -e "  \033[31mFAIL\033[0m  imageUrl = $IMG_CAR1";; esac
req GET "$IMG_CAR1";                         check "Uploaded photo is served over HTTP -> 200" 200

reqform POST /api/cars "$TOKEN" model=Sonata brand=Hyundai pricePerDay=120
check "Create 2nd car (no photo) -> 201" 201
CAR2=$(jqv "['id']")
assert_json "No photo => imageUrl is null"   "['imageUrl']" "None"

reqform POST /api/cars "$TOKEN" model= brand=Kia pricePerDay=100
check "Create car with empty model -> 400" 400
reqform POST /api/cars "$TOKEN" model=Rio brand=Kia pricePerDay=0
check "Create car with price 0 -> 400" 400
reqform POST /api/cars "$TOKEN" model=Rio brand=Kia pricePerDay=-5
check "Create car with negative price -> 400" 400
# BUGFIX: the invariant-culture binder used to read "10,5" as 105 (comma = thousands
# separator), silently storing a 10x price. Group separators are now rejected.
reqform POST /api/cars "$TOKEN" model=Rio brand=Kia pricePerDay=10,5
check "BUGFIX comma decimal '10,5' -> 400 (was stored as 105)" 400

req GET "/api/cars/$CAR1";                   check "Get car by id -> 200" 200
req GET /api/cars/999999;                    check "Get missing car -> 404" 404
req GET /api/cars/abc;                       check "Get car with non-int id -> 404 (route constraint)" 404
req GET "/api/cars?status=Available";        check "Filter cars by status -> 200" 200
req GET "/api/cars?status=Bogus";            check "Filter by invalid status -> 400" 400
req GET /api/cars/available;                 check "GET /api/cars/available (no route conflict)" 200

# ---- 4. customers ------------------------------------------------------------
section "4. Customers + duplicate email"
req POST /api/customers '{"name":"Anas Sadeq","email":"anas@example.com","phone":"0500000000"}' "$TOKEN"
check "Create customer -> 201" 201
CUST1=$(jqv "['id']")
req POST /api/customers '{"name":"Someone Else","email":"anas@example.com","phone":"0511111111"}' "$TOKEN"
check "BUG#9 duplicate email -> 409 (was 500)" 409
# BUGFIX: the duplicate check was case-sensitive on SQLite (though not on SQL Server),
# so the same address with different casing created a duplicate customer.
req POST /api/customers '{"name":"Case Variant","email":"ANAS@Example.COM","phone":"0533333333"}' "$TOKEN"
check "BUGFIX duplicate email different case -> 409" 409
req POST /api/customers '{"name":"Bad Email","email":"not-an-email","phone":"05"}' "$TOKEN"
check "Create customer with invalid email -> 400" 400
req POST /api/customers '{"name":"Second","email":"second@example.com","phone":"0522222222"}' "$TOKEN"
check "Create 2nd customer -> 201" 201
CUST2=$(jqv "['id']")

req PUT "/api/customers/$CUST1" '{"name":"Anas S.","email":"anas@example.com","phone":"0500000001"}' "$TOKEN"
check "Update customer keeping own email -> 200" 200
req PUT "/api/customers/$CUST1" '{"name":"Anas S.","email":"second@example.com","phone":"0500000001"}' "$TOKEN"
check "Update customer to taken email -> 409" 409

# ---- 5. THE BIG ONE: car update must not release a rented car ---------------
section "5. BUG#2 — price edit must NOT release a rented car"
req POST /api/rentals "{\"carId\":$CAR1,\"customerId\":$CUST1,\"startDate\":\"$TOMORROW\",\"endDate\":\"$NEXTWEEK\"}" "$TOKEN"
check "Create rental -> 201" 201
RENT1=$(jqv "['id']")
assert_json "Rental status Active"           "['status']" "Active"
assert_num  "TotalPrice = 150 x 7 days"      "['totalPrice']" "1050"
assert_json "DurationInDays = 7"             "['durationInDays']" "7"

req GET "/api/cars/$CAR1"
assert_json "Car is now Rented"              "['status']" "Rented"

# This is the exact operation that used to silently reset status to Available.
reqform PUT "/api/cars/$CAR1" "$TOKEN" "model=Camry 2024" brand=Toyota pricePerDay=175.00
check "Edit rented car's price -> 200" 200
assert_json "BUG#2 FIXED: still Rented after price edit" "['status']" "Rented"
assert_json "Photo survives the price edit"  "['imageUrl']" "$IMG_CAR1"

reqform PUT "/api/cars/$CAR1" "$TOKEN" "model=Camry 2024" brand=Toyota pricePerDay=175.00 status=Bogus
check "Update car with invalid status -> 400" 400

# ---- 6. rental creation validation ------------------------------------------
section "6. BUG#4/#11 — rental input validation"
req POST /api/rentals "{\"carId\":$CAR2,\"customerId\":999999,\"startDate\":\"$TOMORROW\",\"endDate\":\"$NEXTWEEK\"}" "$TOKEN"
check "BUG#4 nonexistent customer -> 404 (was 500)" 404
req POST /api/rentals "{\"carId\":999999,\"customerId\":$CUST1,\"startDate\":\"$TOMORROW\",\"endDate\":\"$NEXTWEEK\"}" "$TOKEN"
check "Nonexistent car -> 404" 404
req POST /api/rentals "{\"carId\":$CAR2,\"customerId\":$CUST1,\"startDate\":\"$NEXTWEEK\",\"endDate\":\"$TOMORROW\"}" "$TOKEN"
check "EndDate before StartDate -> 400" 400
req POST /api/rentals "{\"carId\":$CAR2,\"customerId\":$CUST1,\"startDate\":\"$TOMORROW\",\"endDate\":\"$TOMORROW\"}" "$TOKEN"
check "Same-day rental -> 400" 400
req POST /api/rentals "{\"carId\":$CAR2,\"customerId\":$CUST1,\"startDate\":\"$YESTERDAY\",\"endDate\":\"$NEXTWEEK\"}" "$TOKEN"
check "BUG#11 past StartDate -> 400 (was allowed)" 400
req POST /api/rentals "{\"carId\":$CAR1,\"customerId\":$CUST2,\"startDate\":\"$TOMORROW\",\"endDate\":\"$NEXTWEEK\"}" "$TOKEN"
check "Double-book same car/dates -> 409" 409
req POST /api/rentals "{\"carId\":$CAR2,\"customerId\":0,\"startDate\":\"$TOMORROW\",\"endDate\":\"$NEXTWEEK\"}" "$TOKEN"
check "CustomerId 0 -> 400 (range validation)" 400

# ---- 7. rental update must not zero the price -------------------------------
section "7. BUG#3 — rental edit must NOT zero TotalPrice or reset status"
req PUT "/api/rentals/$RENT1" "{\"startDate\":\"$TOMORROW\",\"endDate\":\"$LATER\"}" "$TOKEN"
check "Update rental dates -> 200" 200
PRICE=$(jqv "['totalPrice']")
[ "$PRICE" != "0" ] && [ "$PRICE" != "0.00" ] \
  && { PASS=$((PASS+1)); echo -e "  \033[32mPASS\033[0m  BUG#3 FIXED: TotalPrice recalculated = $PRICE"; } \
  || { FAIL=$((FAIL+1)); FAILURES+=("TotalPrice zeroed on update: $PRICE"); echo -e "  \033[31mFAIL\033[0m  TotalPrice = $PRICE"; }
assert_json "Status still Active after date edit" "['status']" "Active"

# A closed historical rental may be corrected even if its new dates overlap a
# current active booking; only an open rental holds the car.
req PUT "/api/rentals/$RENT1/complete" "" "$TOKEN"
check "Close rental before historical-date regression -> 200" 200
req POST /api/rentals "{\"carId\":$CAR1,\"customerId\":$CUST2,\"startDate\":\"$TOMORROW\",\"endDate\":\"$NEXTWEEK\"}" "$TOKEN"
check "Create active booking for overlap regression -> 201" 201
RENT_HISTORY_HOLDER=$(jqv "['id']")
req PUT "/api/rentals/$RENT1" "{\"startDate\":\"$TOMORROW\",\"endDate\":\"$NEXTWEEK\"}" "$TOKEN"
check "Correct closed rental dates over active booking -> 200" 200
assert_json "Closed rental status is preserved" "['status']" "Completed"
req DELETE "/api/rentals/$RENT_HISTORY_HOLDER" "" "$TOKEN"
check "Delete temporary overlap booking -> 204" 204
req PUT "/api/rentals/$RENT1" "{\"startDate\":\"$TOMORROW\",\"endDate\":\"$LATER\",\"status\":\"Active\"}" "$TOKEN"
check "Reopen rental for lifecycle tests -> 200" 200

# ---- 8. rental lifecycle (was completely missing) ---------------------------
section "8. BUG#7 — complete/cancel lifecycle releases the car"
req PUT "/api/rentals/$RENT1/complete" "" "$TOKEN"
check "Complete rental -> 200" 200
assert_json "Rental is Completed"            "['status']" "Completed"
req GET "/api/cars/$CAR1"
assert_json "BUG#7 FIXED: car released to Available" "['status']" "Available"

req PUT "/api/rentals/$RENT1/complete" "" "$TOKEN"
check "Complete an already-completed rental -> 409" 409
req PUT "/api/rentals/$RENT1/cancel" "" "$TOKEN"
check "Cancel a closed rental -> 409" 409
req PUT /api/rentals/999999/complete "" "$TOKEN"
check "Complete missing rental -> 404" 404

# car should be rentable again now
req POST /api/rentals "{\"carId\":$CAR1,\"customerId\":$CUST2,\"startDate\":\"$LATER\",\"endDate\":\"$LATER_END\"}" "$TOKEN"
check "Re-rent the released car -> 201" 201
RENT2=$(jqv "['id']")

# ---- 9. delete must free the car -------------------------------------------
section "9. BUG#6 — deleting an active rental frees its car"
req GET "/api/cars/$CAR1"
assert_json "Car is Rented before delete"    "['status']" "Rented"
req DELETE "/api/rentals/$RENT2" "" "$TOKEN"
check "Delete active rental -> 204" 204
req GET "/api/cars/$CAR1"
assert_json "BUG#6 FIXED: car freed after rental delete" "['status']" "Available"
req DELETE /api/rentals/999999 "" "$TOKEN"
check "Delete missing rental -> 404" 404

# ---- 10. relationship-protected deletes ------------------------------------
section "10. BUG#8/#10 — relationship-aware deletes"
req POST /api/rentals "{\"carId\":$CAR2,\"customerId\":$CUST1,\"startDate\":\"$TOMORROW\",\"endDate\":\"$NEXTWEEK\"}" "$TOKEN"
check "Create rental on car2 -> 201" 201
RENT3=$(jqv "['id']")

req DELETE "/api/cars/$CAR2" "" "$TOKEN"
check "Delete car with ACTIVE rental -> 409" 409
req DELETE "/api/customers/$CUST1" "" "$TOKEN"
check "BUG#8 delete customer w/ active rental -> 409 (was 500)" 409

req PUT "/api/rentals/$RENT3/cancel" "" "$TOKEN"
check "Cancel rental on car2 -> 200" 200
req DELETE "/api/cars/$CAR2" "" "$TOKEN"
check "BUG#10 delete car w/ only history -> 409 + clear reason" 409
req DELETE "/api/customers/$CUST1" "" "$TOKEN"
check "Delete customer w/ history -> 409" 409

req DELETE /api/cars/999999 "" "$TOKEN";     check "Delete missing car -> 404" 404
req DELETE /api/customers/999999 "" "$TOKEN"; check "Delete missing customer -> 404" 404

# a car with no rentals at all should delete cleanly
reqform POST /api/cars "$TOKEN" model=Disposable brand=Test pricePerDay=50
CAR3=$(jqv "['id']")
req DELETE "/api/cars/$CAR3" "" "$TOKEN";    check "Delete car with no rentals -> 204" 204

# ---- 10b. maintenance status blocks renting ---------------------------------
section "10b. UnderMaintenance blocks renting"
reqform POST /api/cars "$TOKEN" model=Yaris brand=Toyota pricePerDay=90
CAR4=$(jqv "['id']")
reqform PUT "/api/cars/$CAR4" "$TOKEN" model=Yaris brand=Toyota pricePerDay=90 status=UnderMaintenance
check "Set car to UnderMaintenance -> 200" 200
assert_json "Status is UnderMaintenance"     "['status']" "UnderMaintenance"
req POST /api/rentals "{\"carId\":$CAR4,\"customerId\":$CUST2,\"startDate\":\"$TOMORROW\",\"endDate\":\"$NEXTWEEK\"}" "$TOKEN"
check "Rent a car under maintenance -> 409" 409
req GET "/api/cars?status=UnderMaintenance"; check "Filter by UnderMaintenance -> 200" 200

# ---- 11. rental reads -------------------------------------------------------
section "11. Rental reads"
req GET /api/rentals "" "$TOKEN";            check "List rentals -> 200" 200
req GET /api/rentals;                        check "List rentals without token -> 401" 401
req GET "/api/rentals/customer/$CUST1" "" "$TOKEN"
check "Rentals by customer -> 200" 200
req GET "/api/rentals/customer/$CUST1"
check "Customer history WITHOUT token -> 401" 401
req GET "/api/rentals/customer/999999" "" "$TOKEN"
check "Rentals for missing customer -> 404" 404
req GET "/api/rentals/$RENT3" "" "$TOKEN";   check "Get rental by id -> 200" 200
assert_json "Rental embeds car summary"      "['car']['brand']" "Hyundai"
assert_json "Rental embeds customer summary" "['customer']['name']" "Anas S."

# ---- 12. car photo lifecycle (single-form flow) ------------------------------
section "12. Car photo lifecycle (same-form upload)"
UPDIR="${UPLOADS_DIR:-CarRental.API/wwwroot/uploads}"
imgcount() { ls "$UPDIR" 2>/dev/null | grep -cE '\.(png|jpg|jpeg|gif|webp)$'; }

# rejected image => the car must NOT be created
reqform POST /api/cars "$TOKEN" model=PhotoFail brand=Test pricePerDay=10 image=@/tmp/t_fake.png
check "Create with text-file-as-.png -> 400 (magic bytes)" 400
req GET /api/cars
NOFAIL=$(python3 -c "
import json;d=json.load(open('/tmp/_body'))
print('absent' if all(c['model']!='PhotoFail' for c in d) else 'present')")
[ "$NOFAIL" = "absent" ] && { PASS=$((PASS+1)); echo -e "  \033[32mPASS\033[0m  Rejected image => car NOT created"; } \
  || { FAIL=$((FAIL+1)); FAILURES+=("car created despite rejected image"); echo -e "  \033[31mFAIL\033[0m  car exists"; }

reqform POST /api/cars "$TOKEN" model=PhotoFail brand=Test pricePerDay=10 image=@/tmp/t_mismatch.jpg
check "Create with PNG-renamed-.jpg -> 400 (format mismatch)" 400
reqform POST /api/cars "$TOKEN" model=PhotoFail brand=Test pricePerDay=10 image=@/tmp/t_huge.png
check "Create with 6 MB file -> 400 (size limit)" 400

# happy path: car + photo in one request
FILES0=$(imgcount)
reqform POST /api/cars "$TOKEN" "model=Photo Test" brand=Test pricePerDay=100 image=@/tmp/t_car.png
check "Create car + photo in one form -> 201" 201
PCAR=$(jqv "['id']")
IMG1=$(jqv "['imageUrl']")
req GET "$IMG1";                      check "Photo served over HTTP -> 200" 200

# PUT with a new file replaces and deletes the old one
reqform PUT "/api/cars/$PCAR" "$TOKEN" "model=Photo Test" brand=Test pricePerDay=100 image=@/tmp/t_car.jpg
check "Replace photo via the same PUT form -> 200" 200
IMG2=$(jqv "['imageUrl']")
req GET "$IMG1";                      check "Old file deleted after replace -> 404" 404

# PUT without an image keeps the photo (the bug that wiped it is fixed)
reqform PUT "/api/cars/$PCAR" "$TOKEN" "model=Photo Test" brand=Test pricePerDay=250
check "Edit price, image field left empty -> 200" 200
assert_json "BUGFIX: photo survives the edit" "['imageUrl']" "$IMG2"

# removeImage=true clears the photo AND deletes the file
reqform PUT "/api/cars/$PCAR" "$TOKEN" "model=Photo Test" brand=Test pricePerDay=250 removeImage=true
check "removeImage=true -> 200" 200
assert_json "imageUrl null after removeImage"  "['imageUrl']" "None"

# PUT with image on a missing car: 404 and no file left behind
FILES_BEFORE=$(imgcount)
reqform PUT /api/cars/999999 "$TOKEN" model=X brand=Y pricePerDay=10 image=@/tmp/t_car.png
check "PUT photo to a missing car -> 404" 404
FILES_AFTER=$(imgcount)
[ "$FILES_BEFORE" = "$FILES_AFTER" ] && { PASS=$((PASS+1)); echo -e "  \033[32mPASS\033[0m  No orphan file for a missing car"; } \
  || { FAIL=$((FAIL+1)); FAILURES+=("orphan file: $FILES_BEFORE -> $FILES_AFTER"); echo -e "  \033[31mFAIL\033[0m  files $FILES_BEFORE -> $FILES_AFTER"; }

# multipart without a token
reqform POST /api/cars "" model=X brand=Y pricePerDay=10 image=@/tmp/t_car.png
check "Form upload without a token -> 401" 401

# deleting the car cleans up its photo file
reqform PUT "/api/cars/$PCAR" "$TOKEN" "model=Photo Test" brand=Test pricePerDay=250 image=@/tmp/t_car.png
check "Give the car a photo again -> 200" 200
req DELETE "/api/cars/$PCAR" "" "$TOKEN"
check "Delete the car -> 204" 204
[ "$(imgcount)" = "$FILES0" ] && { PASS=$((PASS+1)); echo -e "  \033[32mPASS\033[0m  Car's photo file removed with the car"; } \
  || { FAIL=$((FAIL+1)); FAILURES+=("photo left after car delete"); echo -e "  \033[31mFAIL\033[0m  files: $(imgcount) expected $FILES0"; }

# ---- 13. reopening a closed rental --------------------------------------------
section "13. Reopen guard (closed rental -> Active)"
# RENT3 is Cancelled and belongs to CAR2. Put CAR2 under maintenance first:
reqform PUT "/api/cars/$CAR2" "$TOKEN" model=Sonata brand=Hyundai pricePerDay=120 status=UnderMaintenance
check "Put car2 under maintenance -> 200" 200
req PUT "/api/rentals/$RENT3" "{\"startDate\":\"$TOMORROW\",\"endDate\":\"$NEXTWEEK\",\"status\":\"Active\"}" "$TOKEN"
check "BUGFIX: reopen onto a maintenance car -> 409" 409
reqform PUT "/api/cars/$CAR2" "$TOKEN" model=Sonata brand=Hyundai pricePerDay=120 status=Available
check "Car2 back to Available -> 200" 200
req PUT "/api/rentals/$RENT3" "{\"startDate\":\"$TOMORROW\",\"endDate\":\"$NEXTWEEK\",\"status\":\"Active\"}" "$TOKEN"
check "Reopen the cancelled rental -> 200" 200
req GET "/api/cars/$CAR2"
assert_json "Car2 is Rented after the reopen" "['status']" "Rented"
req PUT "/api/rentals/$RENT3/cancel" "" "$TOKEN"
check "Cancel it again -> 200" 200
req GET "/api/cars/$CAR2"
assert_json "Car2 released again" "['status']" "Available"

# ---- 14. dashboard statistics --------------------------------------------------
section "14. Dashboard statistics"
req GET /api/statistics
check "Statistics without token -> 401" 401
req GET "/api/statistics?months=99" "" "$TOKEN"
check "Statistics with months out of range -> 400" 400
req GET /api/statistics "" "$TOKEN"
check "Statistics -> 200" 200
assert_json "cars.total"              "['cars']['total']" "3"
assert_json "cars.available"          "['cars']['available']" "2"
assert_json "cars.underMaintenance"   "['cars']['underMaintenance']" "1"
assert_json "cars.rented"             "['cars']['rented']" "0"
assert_json "customers.total"         "['customers']['total']" "2"
assert_json "rentals.total"           "['rentals']['total']" "2"
assert_json "rentals.active"          "['rentals']['active']" "0"
assert_json "rentals.completed"       "['rentals']['completed']" "1"
assert_json "rentals.cancelled"       "['rentals']['cancelled']" "1"
assert_num  "revenue.total = the completed rental" "['revenue']['total']" "3325"
assert_num  "monthlyRevenue has this month's bar"  "['monthlyRevenue'][0]['revenue']" "3325"

# ---- summary ---------------------------------------------------------------
printf '\n\033[1m══════════════════════════════════════════════════\033[0m\n'
printf '\033[1m  TOTAL: %d passed, %d failed\033[0m\n' "$PASS" "$FAIL"
printf '\033[1m══════════════════════════════════════════════════\033[0m\n'
if [ "$FAIL" -gt 0 ]; then
  echo; echo "FAILURES:"
  for f in "${FAILURES[@]}"; do echo "  - $f"; done
  exit 1
fi
