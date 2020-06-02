import sys, requests, base64

print("Downloading skins from minetest.fensta.bplaced.net ...")
r = requests.get('http://minetest.fensta.bplaced.net/api/v2/get.json.php?getlist&page=1&per_page=999999999')

if r.status_code != 200:
    sys.exit("Request failed!")

data = r.json()
count = 0

print("Writing to file and downloading previews ...")
for json in data["skins"]:
    id = str(json["id"])
    r2 = requests.get('http://minetest.fensta.bplaced.net/skins/1/' + id + ".png")
    if r.status_code == 200:
        preview = r2.content
        name = str(json["name"])
        author = str(json["author"])
        license = str(json["license"])
        #Texture file
        raw_data = base64.b64decode(json["img"])
        file = open("../textures/character_" + id + ".png", "wb")
        file.write(bytearray(raw_data))
        file.close()
        #Preview file
        file = open("../textures/character_" + id + "_preview.png", "wb")
        file.write(bytearray(preview))
        file.close()
        #Meta file
        file = open("../meta/character_" + id + ".txt", "w")
        file.write(name + "\n" + author + "\n" + license + "\n")
        file.close()
        print("Added #%s Name: %s Author: %s License: %s" % (id, name, author, license))
        count += 1

    else:
        print("Fetching of preview of skin " + id + "failed!")


print("Fetched " + str(count) + " skins!")
