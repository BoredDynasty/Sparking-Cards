--!strict

-- starsStructure.luau
-- a FAT string of lots of real stars in the universe.
-- make sure to messagepack.decode this or else,
-- deserializing will be a pain.
-- (imaging decoding this every frame :skull:)

return [[
[
    {
        "NAME": "Sirius",
        "RA": "06H45M008.93S",
        "DEC": "-16D42M058.02S",
        "APPMAG": -1.44,
        "DIST": "8.60LY",
        "SPEC": "A0m..."
    },
    {
        "NAME": "Canopus",
        "RA": "06H23M057.10S",
        "DEC": "-52D41M044.38S",
        "APPMAG": -0.62,
        "DIST": "309.15LY",
        "SPEC": "F0Ib"
    },
    {
        "NAME": "Arcturus",
        "RA": "14H15M039.71S",
        "DEC": "+19D10M056.68S",
        "APPMAG": -0.05,
        "DIST": "36.72LY",
        "SPEC": "K2IIIp"
    },
    {
        "NAME": "Rigil Kentaurus",
        "RA": "14H39M038.75S",
        "DEC": "-60D50M002.31S",
        "APPMAG": -0.01,
        "DIST": "4.32LY",
        "SPEC": "G2V"
    },
    {
        "NAME": "Vega",
        "RA": "18H36M056.30S",
        "DEC": "+38D47M001.29S",
        "APPMAG": 0.03,
        "DIST": "25.04LY",
        "SPEC": "A0Vvar"
    },
    {
        "NAME": "Capella",
        "RA": "05H16M041.34S",
        "DEC": "+45D59M052.77S",
        "APPMAG": 0.08,
        "DIST": "42.80LY",
        "SPEC": "M1: comp"
    },
    {
        "NAME": "Rigel",
        "RA": "05H14M032.27S",
        "DEC": "-08D12M005.90S",
        "APPMAG": 0.18,
        "DIST": "862.85LY",
        "SPEC": "B8Ia"
    },
    {
        "NAME": "Procyon",
        "RA": "07H39M018.12S",
        "DEC": "+05D13M029.97S",
        "APPMAG": 0.4,
        "DIST": "11.46LY",
        "SPEC": "F5IV-V"
    },
    {
        "NAME": "Betelgeuse",
        "RA": "05H55M010.30S",
        "DEC": "+07D24M025.43S",
        "APPMAG": 0.45,
        "DIST": "497.95LY",
        "SPEC": "M2Ib"
    },
    {
        "NAME": "Achernar",
        "RA": "01H37M042.80S",
        "DEC": "-57D14M012.33S",
        "APPMAG": 0.45,
        "DIST": "139.44LY",
        "SPEC": "B3Vp"
    },
    {
        "NAME": "Hadar",
        "RA": "14H03M049.42S",
        "DEC": "-60D22M022.94S",
        "APPMAG": 0.61,
        "DIST": "392.01LY",
        "SPEC": "B1III"
    },
    {
        "NAME": "Altair",
        "RA": "19H50M047.00S",
        "DEC": "+08D52M005.96S",
        "APPMAG": 0.76,
        "DIST": "16.73LY",
        "SPEC": "A7IV-V"
    },
    {
        "NAME": "Acrux",
        "RA": "12H26M035.92S",
        "DEC": "-63D05M056.73S",
        "APPMAG": 0.77,
        "DIST": "321.97LY",
        "SPEC": "B0.5IV"
    },
    {
        "NAME": "Aldebaran",
        "RA": "04H35M055.24S",
        "DEC": "+16D30M033.48S",
        "APPMAG": 0.87,
        "DIST": "66.64LY",
        "SPEC": "K5III"
    },
    {
        "NAME": "Gl 194B",
        "RA": "05H16M040.53S",
        "DEC": "+46D00M003.03S",
        "APPMAG": 0.96,
        "DIST": "42.20LY",
        "SPEC": "G0 III"
    },
    {
        "NAME": "Spica",
        "RA": "13H25M011.58S",
        "DEC": "-11D09M040.76S",
        "APPMAG": 0.98,
        "DIST": "249.74LY",
        "SPEC": "B1V"
    },
    {
        "NAME": "Antares",
        "RA": "16H29M024.46S",
        "DEC": "-26D25M055.21S",
        "APPMAG": 1.06,
        "DIST": "553.75LY",
        "SPEC": "M1Ib + B2.5V"
    },
    {
        "NAME": "Pollux",
        "RA": "07H45M019.00S",
        "DEC": "+28D01M034.32S",
        "APPMAG": 1.16,
        "DIST": "33.78LY",
        "SPEC": "K0IIIvar"
    },
    {
        "NAME": "Fomalhaut",
        "RA": "22H57M039.02S",
        "DEC": "-29D37M020.05S",
        "APPMAG": 1.17,
        "DIST": "25.13LY",
        "SPEC": "A3V"
    },
    {
        "NAME": "Deneb",
        "RA": "20H41M025.92S",
        "DEC": "+45D16M049.22S",
        "APPMAG": 1.25,
        "DIST": "1411.93LY",
        "SPEC": "A2Ia"
    },
    {
        "NAME": "Mimosa",
        "RA": "12H47M043.29S",
        "DEC": "-59D41M019.55S",
        "APPMAG": 1.25,
        "DIST": "278.53LY",
        "SPEC": "B0.5III"
    },
    {
        "NAME": "Toliman",
        "RA": "14H39M037.25S",
        "DEC": "-60D50M017.88S",
        "APPMAG": 1.35,
        "DIST": "4.32LY",
        "SPEC": "K1V"
    },
    {
        "NAME": "Regulus",
        "RA": "10H08M022.32S",
        "DEC": "+11D58M001.95S",
        "APPMAG": 1.36,
        "DIST": "79.30LY",
        "SPEC": "B7V"
    },
    {
        "NAME": "Adhara",
        "RA": "06H58M037.55S",
        "DEC": "-28D58M019.50S",
        "APPMAG": 1.5,
        "DIST": "405.16LY",
        "SPEC": "B2II"
    },
    {
        "NAME": "Castor",
        "RA": "07H34M035.88S",
        "DEC": "+31D53M017.79S",
        "APPMAG": 1.58,
        "DIST": "50.87LY",
        "SPEC": "A2Vm"
    },
    {
        "NAME": "Gacrux",
        "RA": "12H31M009.94S",
        "DEC": "-57D06M047.56S",
        "APPMAG": 1.59,
        "DIST": "88.56LY",
        "SPEC": "M4III"
    },
    {
        "NAME": "Shaula",
        "RA": "17H33M036.52S",
        "DEC": "-37D06M013.76S",
        "APPMAG": 1.62,
        "DIST": "571.20LY",
        "SPEC": "B1.5IV+..."
    },
    {
        "NAME": "Bellatrix",
        "RA": "05H25M007.86S",
        "DEC": "+06D20M058.93S",
        "APPMAG": 1.64,
        "DIST": "252.44LY",
        "SPEC": "B2III"
    },
    {
        "NAME": "Elnath",
        "RA": "05H26M017.51S",
        "DEC": "+28D36M026.82S",
        "APPMAG": 1.65,
        "DIST": "133.89LY",
        "SPEC": "B7III"
    },
    {
        "NAME": "Miaplacidus",
        "RA": "09H13M012.15S",
        "DEC": "-69D43M001.95S",
        "APPMAG": 1.67,
        "DIST": "113.17LY",
        "SPEC": "A2IV"
    },
    {
        "NAME": "Alnilam",
        "RA": "05H36M012.81S",
        "DEC": "-01D12M006.91S",
        "APPMAG": 1.69,
        "DIST": "1976.71LY",
        "SPEC": "B0Ia"
    },
    {
        "NAME": "Alnair",
        "RA": "22H08M013.95S",
        "DEC": "-46D57M039.51S",
        "APPMAG": 1.73,
        "DIST": "101.01LY",
        "SPEC": "B7IV"
    },
    {
        "NAME": "Alnitak",
        "RA": "05H40M045.53S",
        "DEC": "-01D56M033.26S",
        "APPMAG": 1.74,
        "DIST": "736.24LY",
        "SPEC": "O9.5Ib SB"
    },
    {
        "NAME": "Gam2Vel",
        "RA": "08H09M031.95S",
        "DEC": "-47D20M011.72S",
        "APPMAG": 1.75,
        "DIST": "1116.97LY",
        "SPEC": "WC8 + O9I"
    },
    {
        "NAME": "Alioth",
        "RA": "12H54M001.70S",
        "DEC": "+55D57M035.36S",
        "APPMAG": 1.76,
        "DIST": "82.55LY",
        "SPEC": "A0p"
    },
    {
        "NAME": "Kaus Australis",
        "RA": "18H24M010.32S",
        "DEC": "-34D23M004.62S",
        "APPMAG": 1.79,
        "DIST": "143.30LY",
        "SPEC": "B9.5III"
    },
    {
        "NAME": "Mirfak",
        "RA": "03H24M019.36S",
        "DEC": "+49D51M040.25S",
        "APPMAG": 1.79,
        "DIST": "506.45LY",
        "SPEC": "F5Ib"
    },
    {
        "NAME": "Dubhe",
        "RA": "11H03M043.76S",
        "DEC": "+61D45M003.72S",
        "APPMAG": 1.81,
        "DIST": "122.89LY",
        "SPEC": "F7V comp"
    },
    {
        "NAME": "Wezen",
        "RA": "07H08M023.49S",
        "DEC": "-26D23M035.52S",
        "APPMAG": 1.83,
        "DIST": "1606.68LY",
        "SPEC": "F8Ia"
    },
    {
        "NAME": "Alkaid",
        "RA": "13H47M032.47S",
        "DEC": "+49D18M047.75S",
        "APPMAG": 1.85,
        "DIST": "103.94LY",
        "SPEC": "B3V SB"
    },
    {
        "NAME": "Sargas",
        "RA": "17H37M019.13S",
        "DEC": "-42D59M052.17S",
        "APPMAG": 1.86,
        "DIST": "300.33LY",
        "SPEC": "F1II"
    },
    {
        "NAME": "Avior",
        "RA": "08H22M030.85S",
        "DEC": "-59D30M034.14S",
        "APPMAG": 1.86,
        "DIST": "605.11LY",
        "SPEC": "K3III+B2V"
    },
    {
        "NAME": "Menkalinan",
        "RA": "05H59M031.74S",
        "DEC": "+44D56M050.76S",
        "APPMAG": 1.9,
        "DIST": "81.11LY",
        "SPEC": "A2V"
    },
    {
        "NAME": "Atria",
        "RA": "16H48M039.88S",
        "DEC": "-69D01M039.77S",
        "APPMAG": 1.91,
        "DIST": "390.61LY",
        "SPEC": "K2IIb-IIIa"
    },
    {
        "NAME": "Alsephina",
        "RA": "08H44M042.21S",
        "DEC": "-54D42M031.76S",
        "APPMAG": 1.93,
        "DIST": "80.55LY",
        "SPEC": "A1V"
    },
    {
        "NAME": "Alhena",
        "RA": "06H37M042.70S",
        "DEC": "+16D23M057.31S",
        "APPMAG": 1.93,
        "DIST": "109.30LY",
        "SPEC": "A0IV"
    },
    {
        "NAME": "Peacock",
        "RA": "20H25M038.85S",
        "DEC": "-56D44M006.32S",
        "APPMAG": 1.94,
        "DIST": "178.81LY",
        "SPEC": "B2IV"
    },
    {
        "NAME": "Polaris",
        "RA": "02H31M047.10S",
        "DEC": "+89D15M050.79S",
        "APPMAG": 1.97,
        "DIST": "432.57LY",
        "SPEC": "F7:Ib-IIv SB"
    },
    {
        "NAME": "Mirzam",
        "RA": "06H22M041.98S",
        "DEC": "-17D57M021.30S",
        "APPMAG": 1.98,
        "DIST": "492.68LY",
        "SPEC": "B1II/III"
    },
    {
        "NAME": "Alphard",
        "RA": "09H27M035.24S",
        "DEC": "-08D39M030.97S",
        "APPMAG": 1.99,
        "DIST": "180.30LY",
        "SPEC": "K3III"
    },
    {
        "NAME": "Hamal",
        "RA": "02H07M010.40S",
        "DEC": "+23D27M044.72S",
        "APPMAG": 2.01,
        "DIST": "65.81LY",
        "SPEC": "K2III"
    },
    {
        "NAME": "Algieba",
        "RA": "10H19M058.34S",
        "DEC": "+19D50M029.36S",
        "APPMAG": 2.01,
        "DIST": "130.10LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "Diphda",
        "RA": "00H43M035.36S",
        "DEC": "-17D59M011.78S",
        "APPMAG": 2.04,
        "DIST": "96.33LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "Nunki",
        "RA": "18H55M015.92S",
        "DEC": "-26D17M048.20S",
        "APPMAG": 2.05,
        "DIST": "227.76LY",
        "SPEC": "B2.5V"
    },
    {
        "NAME": "Menkent",
        "RA": "14H06M041.02S",
        "DEC": "-36D22M011.83S",
        "APPMAG": 2.06,
        "DIST": "58.82LY",
        "SPEC": "K0IIIb"
    },
    {
        "NAME": "Kochab",
        "RA": "14H50M042.38S",
        "DEC": "+74D09M019.82S",
        "APPMAG": 2.07,
        "DIST": "130.93LY",
        "SPEC": "K4IIIvar"
    },
    {
        "NAME": "Mirach",
        "RA": "01H09M043.90S",
        "DEC": "+35D37M014.01S",
        "APPMAG": 2.07,
        "DIST": "197.43LY",
        "SPEC": "M0IIIvar"
    },
    {
        "NAME": "Saiph",
        "RA": "05H47M045.39S",
        "DEC": "-09D40M010.58S",
        "APPMAG": 2.07,
        "DIST": "647.14LY",
        "SPEC": "B0.5Iavar"
    },
    {
        "NAME": "Tiaki",
        "RA": "22H42M040.01S",
        "DEC": "-46D53M004.48S",
        "APPMAG": 2.07,
        "DIST": "176.97LY",
        "SPEC": "M5III"
    },
    {
        "NAME": "Alpheratz",
        "RA": "00H08M023.25S",
        "DEC": "+29D05M025.56S",
        "APPMAG": 2.07,
        "DIST": "97.01LY",
        "SPEC": "B9p"
    },
    {
        "NAME": "Rasalhague",
        "RA": "17H34M056.07S",
        "DEC": "+12D33M036.13S",
        "APPMAG": 2.08,
        "DIST": "48.59LY",
        "SPEC": "A5III"
    },
    {
        "NAME": "Algol",
        "RA": "03H08M010.13S",
        "DEC": "+40D57M020.33S",
        "APPMAG": 2.09,
        "DIST": "89.92LY",
        "SPEC": "B8V"
    },
    {
        "NAME": "Almach",
        "RA": "02H03M053.94S",
        "DEC": "+42D19M047.01S",
        "APPMAG": 2.1,
        "DIST": "392.96LY",
        "SPEC": "B8V"
    },
    {
        "NAME": "Denebola",
        "RA": "11H49M003.59S",
        "DEC": "+14D34M019.42S",
        "APPMAG": 2.14,
        "DIST": "35.88LY",
        "SPEC": "A3Vvar"
    },
    {
        "NAME": "Cih",
        "RA": "00H56M042.51S",
        "DEC": "+60D43M000.26S",
        "APPMAG": 2.15,
        "DIST": "549.08LY",
        "SPEC": "B0IV:evar"
    },
    {
        "NAME": "Gam Cen",
        "RA": "12H41M031.10S",
        "DEC": "-48D57M035.60S",
        "APPMAG": 2.2,
        "DIST": "130.15LY",
        "SPEC": "A1IV"
    },
    {
        "NAME": "Aspidiske",
        "RA": "09H17M005.42S",
        "DEC": "-59D16M030.82S",
        "APPMAG": 2.21,
        "DIST": "765.63LY",
        "SPEC": "A8Ib"
    },
    {
        "NAME": "Naos",
        "RA": "08H03M035.05S",
        "DEC": "-40D00M011.33S",
        "APPMAG": 2.21,
        "DIST": "1083.58LY",
        "SPEC": "O5IAf"
    },
    {
        "NAME": "Alphecca",
        "RA": "15H34M041.26S",
        "DEC": "+26D42M052.89S",
        "APPMAG": 2.22,
        "DIST": "75.05LY",
        "SPEC": "A0V"
    },
    {
        "NAME": "Suhail",
        "RA": "09H07M059.76S",
        "DEC": "-43D25M057.32S",
        "APPMAG": 2.23,
        "DIST": "544.50LY",
        "SPEC": "K4Ib-II"
    },
    {
        "NAME": "Mizar",
        "RA": "13H23M055.49S",
        "DEC": "+54D55M031.30S",
        "APPMAG": 2.23,
        "DIST": "85.81LY",
        "SPEC": "A2V"
    },
    {
        "NAME": "Sadr",
        "RA": "20H22M013.70S",
        "DEC": "+40D15M024.04S",
        "APPMAG": 2.23,
        "DIST": "1832.34LY",
        "SPEC": "F8Ib"
    },
    {
        "NAME": "Eltanin",
        "RA": "17H56M036.37S",
        "DEC": "+51D29M020.02S",
        "APPMAG": 2.24,
        "DIST": "154.28LY",
        "SPEC": "K5III"
    },
    {
        "NAME": "Schedar",
        "RA": "00H40M030.42S",
        "DEC": "+56D32M014.39S",
        "APPMAG": 2.24,
        "DIST": "228.24LY",
        "SPEC": "K0II-IIIvar"
    },
    {
        "NAME": "Mintaka",
        "RA": "05H32M000.40S",
        "DEC": "-00D17M056.73S",
        "APPMAG": 2.25,
        "DIST": "692.48LY",
        "SPEC": "O9.5II"
    },
    {
        "NAME": "Caph",
        "RA": "00H09M010.39S",
        "DEC": "+59D08M059.21S",
        "APPMAG": 2.28,
        "DIST": "54.74LY",
        "SPEC": "F2III-IV"
    },
    {
        "NAME": "Dschubba",
        "RA": "16H00M020.01S",
        "DEC": "-22D37M018.16S",
        "APPMAG": 2.29,
        "DIST": "491.20LY",
        "SPEC": "B0.2IV"
    },
    {
        "NAME": "Larawag",
        "RA": "16H50M009.89S",
        "DEC": "-34D17M035.64S",
        "APPMAG": 2.29,
        "DIST": "63.71LY",
        "SPEC": "K2IIIb"
    },
    {
        "NAME": "Eps Cen",
        "RA": "13H39M053.27S",
        "DEC": "-53D27M059.02S",
        "APPMAG": 2.29,
        "DIST": "427.47LY",
        "SPEC": "B1III"
    },
    {
        "NAME": "Alp Lup",
        "RA": "14H41M055.76S",
        "DEC": "-47D23M017.52S",
        "APPMAG": 2.3,
        "DIST": "464.61LY",
        "SPEC": "B1.5III"
    },
    {
        "NAME": "Eta Cen",
        "RA": "14H35M030.43S",
        "DEC": "-42D09M028.17S",
        "APPMAG": 2.33,
        "DIST": "305.68LY",
        "SPEC": "B1Vn + A"
    },
    {
        "NAME": "Merak",
        "RA": "11H01M050.44S",
        "DEC": "+56D22M056.74S",
        "APPMAG": 2.34,
        "DIST": "79.74LY",
        "SPEC": "A1V"
    },
    {
        "NAME": "Izar",
        "RA": "14H44M059.22S",
        "DEC": "+27D04M027.20S",
        "APPMAG": 2.35,
        "DIST": "202.58LY",
        "SPEC": "A0"
    },
    {
        "NAME": "Enif",
        "RA": "21H44M011.16S",
        "DEC": "+09D52M030.04S",
        "APPMAG": 2.38,
        "DIST": "689.55LY",
        "SPEC": "K2Ibvar"
    },
    {
        "NAME": "Kap Sco",
        "RA": "17H42M029.28S",
        "DEC": "-39D01M047.94S",
        "APPMAG": 2.39,
        "DIST": "483.19LY",
        "SPEC": "B1.5III"
    },
    {
        "NAME": "Ankaa",
        "RA": "00H26M017.00S",
        "DEC": "-42D18M021.53S",
        "APPMAG": 2.4,
        "DIST": "84.72LY",
        "SPEC": "K0III..."
    },
    {
        "NAME": "Phecda",
        "RA": "11H53M049.80S",
        "DEC": "+53D41M041.14S",
        "APPMAG": 2.41,
        "DIST": "83.18LY",
        "SPEC": "A0V SB"
    },
    {
        "NAME": "Sabik",
        "RA": "17H10M022.68S",
        "DEC": "-15D43M029.68S",
        "APPMAG": 2.43,
        "DIST": "88.37LY",
        "SPEC": "A2.5Va"
    },
    {
        "NAME": "Scheat",
        "RA": "23H03M046.44S",
        "DEC": "+28D04M058.04S",
        "APPMAG": 2.44,
        "DIST": "196.01LY",
        "SPEC": "M2II-IIIvar"
    },
    {
        "NAME": "Alderamin",
        "RA": "21H18M034.67S",
        "DEC": "+62D35M008.06S",
        "APPMAG": 2.45,
        "DIST": "49.05LY",
        "SPEC": "A7IV-V"
    },
    {
        "NAME": "Aludra",
        "RA": "07H24M005.70S",
        "DEC": "-29D18M011.17S",
        "APPMAG": 2.45,
        "DIST": "1988.76LY",
        "SPEC": "B5Ia"
    },
    {
        "NAME": "Markeb",
        "RA": "09H22M006.82S",
        "DEC": "-55D00M038.40S",
        "APPMAG": 2.47,
        "DIST": "572.20LY",
        "SPEC": "B2IV"
    },
    {
        "NAME": "Aljanah",
        "RA": "20H46M012.64S",
        "DEC": "+33D58M012.92S",
        "APPMAG": 2.48,
        "DIST": "72.71LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "Markab",
        "RA": "23H04M045.65S",
        "DEC": "+15D12M018.95S",
        "APPMAG": 2.49,
        "DIST": "133.34LY",
        "SPEC": "B9.5III"
    },
    {
        "NAME": "Menkar",
        "RA": "03H02M016.77S",
        "DEC": "+04D05M023.04S",
        "APPMAG": 2.54,
        "DIST": "249.16LY",
        "SPEC": "M2III"
    },
    {
        "NAME": "13Zet Oph",
        "RA": "16H37M009.54S",
        "DEC": "-10D34M001.52S",
        "APPMAG": 2.54,
        "DIST": "366.06LY",
        "SPEC": "O9.5V"
    },
    {
        "NAME": "Zet Cen",
        "RA": "13H55M032.40S",
        "DEC": "-47D17M018.15S",
        "APPMAG": 2.55,
        "DIST": "381.92LY",
        "SPEC": "B2.5IV"
    },
    {
        "NAME": "Zosma",
        "RA": "11H14M006.50S",
        "DEC": "+20D31M025.38S",
        "APPMAG": 2.56,
        "DIST": "58.43LY",
        "SPEC": "A4V"
    },
    {
        "NAME": "Acrab",
        "RA": "16H05M026.23S",
        "DEC": "-19D48M019.63S",
        "APPMAG": 2.56,
        "DIST": "404.16LY",
        "SPEC": "B0.5V"
    },
    {
        "NAME": "Del Cen",
        "RA": "12H08M021.52S",
        "DEC": "-50D43M020.73S",
        "APPMAG": 2.58,
        "DIST": "414.96LY",
        "SPEC": "B2IVne"
    },
    {
        "NAME": "Gienah",
        "RA": "12H15M048.37S",
        "DEC": "-17D32M030.94S",
        "APPMAG": 2.58,
        "DIST": "153.63LY",
        "SPEC": "B8III"
    },
    {
        "NAME": "Arneb",
        "RA": "05H32M043.81S",
        "DEC": "-17D49M020.24S",
        "APPMAG": 2.58,
        "DIST": "2218.75LY",
        "SPEC": "F0Ib"
    },
    {
        "NAME": "Ascella",
        "RA": "19H02M036.72S",
        "DEC": "-29D52M048.38S",
        "APPMAG": 2.6,
        "DIST": "88.20LY",
        "SPEC": "A3IV"
    },
    {
        "NAME": "Zubeneschamali",
        "RA": "15H17M000.42S",
        "DEC": "-09D22M058.50S",
        "APPMAG": 2.61,
        "DIST": "185.11LY",
        "SPEC": "B8V"
    },
    {
        "NAME": "Unukalhai",
        "RA": "15H44M016.07S",
        "DEC": "+06D25M032.26S",
        "APPMAG": 2.63,
        "DIST": "73.96LY",
        "SPEC": "K2III"
    },
    {
        "NAME": "Sheratan",
        "RA": "01H54M038.40S",
        "DEC": "+20D48M028.93S",
        "APPMAG": 2.64,
        "DIST": "58.66LY",
        "SPEC": "A5V..."
    },
    {
        "NAME": "Mahasim",
        "RA": "05H59M043.26S",
        "DEC": "+37D12M045.31S",
        "APPMAG": 2.65,
        "DIST": "165.56LY",
        "SPEC": "A0p Si"
    },
    {
        "NAME": "Phact",
        "RA": "05H39M038.94S",
        "DEC": "-34D04M026.79S",
        "APPMAG": 2.65,
        "DIST": "261.34LY",
        "SPEC": "B7IV"
    },
    {
        "NAME": "Kraz",
        "RA": "12H34M023.24S",
        "DEC": "-23D23M048.33S",
        "APPMAG": 2.65,
        "DIST": "145.67LY",
        "SPEC": "G5II"
    },
    {
        "NAME": "Ruchbah",
        "RA": "01H25M048.78S",
        "DEC": "+60D14M007.02S",
        "APPMAG": 2.66,
        "DIST": "99.41LY",
        "SPEC": "A5Vv SB"
    },
    {
        "NAME": "Muphrid",
        "RA": "13H54M041.08S",
        "DEC": "+18D23M051.78S",
        "APPMAG": 2.68,
        "DIST": "37.17LY",
        "SPEC": "G0IV"
    },
    {
        "NAME": "Bet Lup",
        "RA": "14H58M031.93S",
        "DEC": "-43D08M002.26S",
        "APPMAG": 2.68,
        "DIST": "382.81LY",
        "SPEC": "B2III"
    },
    {
        "NAME": "Alp Mus",
        "RA": "12H37M011.06S",
        "DEC": "-69D08M008.03S",
        "APPMAG": 2.69,
        "DIST": "315.43LY",
        "SPEC": "B2IV-V"
    },
    {
        "NAME": "Hassaleh",
        "RA": "04H56M059.62S",
        "DEC": "+33D09M057.92S",
        "APPMAG": 2.69,
        "DIST": "493.43LY",
        "SPEC": "K3IIvar"
    },
    {
        "NAME": "Mu  Vel",
        "RA": "10H46M046.16S",
        "DEC": "-49D25M012.92S",
        "APPMAG": 2.69,
        "DIST": "117.15LY",
        "SPEC": "G5III SB"
    },
    {
        "NAME": "Lesath",
        "RA": "17H30M045.84S",
        "DEC": "-37D17M044.92S",
        "APPMAG": 2.7,
        "DIST": "576.25LY",
        "SPEC": "B2IV"
    },
    {
        "NAME": "Pi  Pup",
        "RA": "07H17M008.56S",
        "DEC": "-37D05M050.89S",
        "APPMAG": 2.71,
        "DIST": "807.32LY",
        "SPEC": "K3Ib"
    },
    {
        "NAME": "Kaus Media",
        "RA": "18H20M059.64S",
        "DEC": "-29D49M041.17S",
        "APPMAG": 2.72,
        "DIST": "347.71LY",
        "SPEC": "K3III"
    },
    {
        "NAME": "Tarazed",
        "RA": "19H46M015.58S",
        "DEC": "+10D36M047.74S",
        "APPMAG": 2.72,
        "DIST": "394.86LY",
        "SPEC": "K3II"
    },
    {
        "NAME": "Athebyne",
        "RA": "16H23M059.50S",
        "DEC": "+61D30M051.17S",
        "APPMAG": 2.73,
        "DIST": "92.08LY",
        "SPEC": "G8III"
    },
    {
        "NAME": "Yed Prior",
        "RA": "16H14M020.74S",
        "DEC": "-03D41M039.56S",
        "APPMAG": 2.73,
        "DIST": "171.12LY",
        "SPEC": "M1III"
    },
    {
        "NAME": "Porrima",
        "RA": "12H41M039.64S",
        "DEC": "-01D26M057.75S",
        "APPMAG": 2.74,
        "DIST": "38.11LY",
        "SPEC": "F0V+..."
    },
    {
        "NAME": "The Car",
        "RA": "10H42M057.42S",
        "DEC": "-64D23M040.02S",
        "APPMAG": 2.74,
        "DIST": "455.53LY",
        "SPEC": "B0Vp"
    },
    {
        "NAME": "Zubenelgenubi",
        "RA": "14H50M052.72S",
        "DEC": "-16D02M030.40S",
        "APPMAG": 2.75,
        "DIST": "75.80LY",
        "SPEC": "A3IV"
    },
    {
        "NAME": "Iot Cen",
        "RA": "13H20M035.87S",
        "DEC": "-36D42M044.26S",
        "APPMAG": 2.75,
        "DIST": "58.78LY",
        "SPEC": "A2V"
    },
    {
        "NAME": "Hatysa",
        "RA": "05H35M025.98S",
        "DEC": "-05D54M035.64S",
        "APPMAG": 2.75,
        "DIST": "2329.69LY",
        "SPEC": "O9III"
    },
    {
        "NAME": "Cebalrai",
        "RA": "17H43M028.35S",
        "DEC": "+04D34M002.29S",
        "APPMAG": 2.76,
        "DIST": "81.85LY",
        "SPEC": "K2III"
    },
    {
        "NAME": "Rasalgethi",
        "RA": "17H14M038.86S",
        "DEC": "+14D23M025.20S",
        "APPMAG": 2.78,
        "DIST": "359.60LY",
        "SPEC": "M5IIvar"
    },
    {
        "NAME": "Kornephoros",
        "RA": "16H30M013.20S",
        "DEC": "+21D29M022.61S",
        "APPMAG": 2.78,
        "DIST": "139.15LY",
        "SPEC": "G8III"
    },
    {
        "NAME": "Cursa",
        "RA": "05H07M050.98S",
        "DEC": "-05D05M011.21S",
        "APPMAG": 2.78,
        "DIST": "89.36LY",
        "SPEC": "A3IIIvar"
    },
    {
        "NAME": "Rastaban",
        "RA": "17H30M025.97S",
        "DEC": "+52D18M004.99S",
        "APPMAG": 2.79,
        "DIST": "380.14LY",
        "SPEC": "G2II"
    },
    {
        "NAME": "Imai",
        "RA": "12H15M008.74S",
        "DEC": "-58D44M056.14S",
        "APPMAG": 2.79,
        "DIST": "345.14LY",
        "SPEC": "B2IV"
    },
    {
        "NAME": "Gam Lup",
        "RA": "15H35M008.45S",
        "DEC": "-41D10M000.33S",
        "APPMAG": 2.8,
        "DIST": "420.85LY",
        "SPEC": "B2IV"
    },
    {
        "NAME": "40Zet Her",
        "RA": "16H41M017.21S",
        "DEC": "+31D36M009.81S",
        "APPMAG": 2.81,
        "DIST": "34.95LY",
        "SPEC": "F9IV"
    },
    {
        "NAME": "Nihal",
        "RA": "05H28M014.72S",
        "DEC": "-20D45M033.99S",
        "APPMAG": 2.81,
        "DIST": "160.35LY",
        "SPEC": "G5II"
    },
    {
        "NAME": "Paikauhale",
        "RA": "16H35M052.95S",
        "DEC": "-28D12M057.66S",
        "APPMAG": 2.82,
        "DIST": "474.06LY",
        "SPEC": "B0V"
    },
    {
        "NAME": "Kaus Borealis",
        "RA": "18H27M058.24S",
        "DEC": "-25D25M018.12S",
        "APPMAG": 2.82,
        "DIST": "78.18LY",
        "SPEC": "K1IIIb"
    },
    {
        "NAME": "Bet Hyi",
        "RA": "00H25M040.50S",
        "DEC": "-77D15M015.29S",
        "APPMAG": 2.82,
        "DIST": "24.33LY",
        "SPEC": "G2IV"
    },
    {
        "NAME": "Algenib",
        "RA": "00H13M014.15S",
        "DEC": "+15D11M000.95S",
        "APPMAG": 2.83,
        "DIST": "391.54LY",
        "SPEC": "B2IV"
    },
    {
        "NAME": "Bet TrA",
        "RA": "15H55M008.70S",
        "DEC": "-63D25M050.62S",
        "APPMAG": 2.83,
        "DIST": "40.37LY",
        "SPEC": "F2III"
    },
    {
        "NAME": "Tureis",
        "RA": "08H07M032.65S",
        "DEC": "-24D18M015.57S",
        "APPMAG": 2.83,
        "DIST": "63.54LY",
        "SPEC": "F2mF5IIp"
    },
    {
        "NAME": "Alp Ara",
        "RA": "17H31M050.50S",
        "DEC": "-49D52M034.12S",
        "APPMAG": 2.84,
        "DIST": "267.34LY",
        "SPEC": "B2Vne"
    },
    {
        "NAME": "44Zet Per",
        "RA": "03H54M007.92S",
        "DEC": "+31D53M001.09S",
        "APPMAG": 2.84,
        "DIST": "751.51LY",
        "SPEC": "B1Ib"
    },
    {
        "NAME": "Bet Ara",
        "RA": "17H25M017.99S",
        "DEC": "-55D31M047.58S",
        "APPMAG": 2.84,
        "DIST": "645.85LY",
        "SPEC": "K3Ib-II"
    },
    {
        "NAME": "Deneb Algedi",
        "RA": "21H47M002.44S",
        "DEC": "-16D07M038.23S",
        "APPMAG": 2.85,
        "DIST": "38.70LY",
        "SPEC": "A5mF2 (IV)"
    },
    {
        "NAME": "Vindemiatrix",
        "RA": "13H02M010.60S",
        "DEC": "+10D57M032.94S",
        "APPMAG": 2.85,
        "DIST": "109.60LY",
        "SPEC": "G8IIIvar"
    },
    {
        "NAME": "Alcyone",
        "RA": "03H47M029.08S",
        "DEC": "+24D06M018.49S",
        "APPMAG": 2.85,
        "DIST": "403.16LY",
        "SPEC": "B7III"
    },
    {
        "NAME": "66Alp Gem",
        "RA": "07H34M036.58S",
        "DEC": "+31D53M025.87S",
        "APPMAG": 2.85,
        "DIST": "51.55LY",
        "SPEC": "A m"
    },
    {
        "NAME": "Alp Hyi",
        "RA": "01H58M046.02S",
        "DEC": "-61D34M011.49S",
        "APPMAG": 2.86,
        "DIST": "71.79LY",
        "SPEC": "F0V"
    },
    {
        "NAME": "Fawaris",
        "RA": "19H44M058.47S",
        "DEC": "+45D07M050.92S",
        "APPMAG": 2.86,
        "DIST": "164.98LY",
        "SPEC": "B9.5III"
    },
    {
        "NAME": "Gam TrA",
        "RA": "15H18M054.65S",
        "DEC": "-68D40M046.36S",
        "APPMAG": 2.87,
        "DIST": "183.85LY",
        "SPEC": "A1V"
    },
    {
        "NAME": "Alp Tuc",
        "RA": "22H18M030.14S",
        "DEC": "-60D15M034.51S",
        "APPMAG": 2.87,
        "DIST": "199.73LY",
        "SPEC": "K3III"
    },
    {
        "NAME": "Tejat",
        "RA": "06H22M057.62S",
        "DEC": "+22D30M048.91S",
        "APPMAG": 2.87,
        "DIST": "231.65LY",
        "SPEC": "M3IIIvar"
    },
    {
        "NAME": "Acamar",
        "RA": "02H58M015.68S",
        "DEC": "-40D18M016.82S",
        "APPMAG": 2.88,
        "DIST": "161.22LY",
        "SPEC": "A4III+..."
    },
    {
        "NAME": "Albaldah",
        "RA": "19H09M045.83S",
        "DEC": "-21D01M025.01S",
        "APPMAG": 2.88,
        "DIST": "509.62LY",
        "SPEC": "F2II/III"
    },
    {
        "NAME": "Fang",
        "RA": "15H58M051.11S",
        "DEC": "-26D06M050.78S",
        "APPMAG": 2.89,
        "DIST": "585.56LY",
        "SPEC": "B1V + B2V"
    },
    {
        "NAME": "Cor Caroli",
        "RA": "12H56M001.71S",
        "DEC": "+38D19M006.17S",
        "APPMAG": 2.89,
        "DIST": "114.80LY",
        "SPEC": "A0spe..."
    },
    {
        "NAME": "Gomeisa",
        "RA": "07H27M009.04S",
        "DEC": "+08D17M021.53S",
        "APPMAG": 2.89,
        "DIST": "161.70LY",
        "SPEC": "B8Vvar"
    },
    {
        "NAME": "Alniyat",
        "RA": "16H21M011.31S",
        "DEC": "-25D35M034.07S",
        "APPMAG": 2.9,
        "DIST": "696.92LY",
        "SPEC": "B1III"
    },
    {
        "NAME": "Sadalsuud",
        "RA": "21H31M033.54S",
        "DEC": "-05D34M016.22S",
        "APPMAG": 2.9,
        "DIST": "537.33LY",
        "SPEC": "G0Ib"
    },
    {
        "NAME": "45Eps Per",
        "RA": "03H57M051.23S",
        "DEC": "+40D00M036.77S",
        "APPMAG": 2.9,
        "DIST": "638.27LY",
        "SPEC": "B0.5V"
    },
    {
        "NAME": "23Gam Per",
        "RA": "03H04M047.79S",
        "DEC": "+53D30M023.18S",
        "APPMAG": 2.91,
        "DIST": "243.22LY",
        "SPEC": "G8III+..."
    },
    {
        "NAME": "Ups Car",
        "RA": "09H47M006.13S",
        "DEC": "-65D04M019.23S",
        "APPMAG": 2.92,
        "DIST": "1436.81LY",
        "SPEC": "A9"
    },
    {
        "NAME": "Matar",
        "RA": "22H43M000.13S",
        "DEC": "+30D13M016.48S",
        "APPMAG": 2.93,
        "DIST": "214.29LY",
        "SPEC": "G2II-III.."
    },
    {
        "NAME": "Algorab",
        "RA": "12H29M051.86S",
        "DEC": "-16D30M055.56S",
        "APPMAG": 2.94,
        "DIST": "86.86LY",
        "SPEC": "B9.5V"
    },
    {
        "NAME": "Tau Pup",
        "RA": "06H49M056.16S",
        "DEC": "-50D36M052.42S",
        "APPMAG": 2.94,
        "DIST": "182.01LY",
        "SPEC": "K0III..."
    },
    {
        "NAME": "Sadalmelik",
        "RA": "22H05M047.04S",
        "DEC": "-00D19M011.46S",
        "APPMAG": 2.95,
        "DIST": "523.53LY",
        "SPEC": "G2Ib"
    },
    {
        "NAME": "Zaurak",
        "RA": "03H58M001.77S",
        "DEC": "-13D30M030.65S",
        "APPMAG": 2.97,
        "DIST": "203.34LY",
        "SPEC": "M1IIIb Ca-1"
    },
    {
        "NAME": "Ras Elased Australis",
        "RA": "09H45M051.08S",
        "DEC": "+23D46M027.32S",
        "APPMAG": 2.97,
        "DIST": "246.71LY",
        "SPEC": "G0II"
    },
    {
        "NAME": "Tianguan",
        "RA": "05H37M038.69S",
        "DEC": "+21D08M033.18S",
        "APPMAG": 2.97,
        "DIST": "444.96LY",
        "SPEC": "B4IIIp"
    },
    {
        "NAME": "Alnasl",
        "RA": "18H05M048.49S",
        "DEC": "-30D25M026.73S",
        "APPMAG": 2.98,
        "DIST": "96.87LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "Okab",
        "RA": "19H05M024.61S",
        "DEC": "+13D51M048.52S",
        "APPMAG": 2.99,
        "DIST": "83.03LY",
        "SPEC": "A0Vn"
    },
    {
        "NAME": "Iot1Sco",
        "RA": "17H47M035.08S",
        "DEC": "-40D07M037.19S",
        "APPMAG": 2.99,
        "DIST": "1929.92LY",
        "SPEC": "F3Ia"
    },
    {
        "NAME": "46Gam Hya",
        "RA": "13H18M055.29S",
        "DEC": "-23D10M017.44S",
        "APPMAG": 2.99,
        "DIST": "133.84LY",
        "SPEC": "G8III"
    },
    {
        "NAME": "4Bet Tri",
        "RA": "02H09M032.61S",
        "DEC": "+34D59M014.27S",
        "APPMAG": 3.0,
        "DIST": "126.86LY",
        "SPEC": "A5III"
    },
    {
        "NAME": "52Psi UMa",
        "RA": "11H09M039.82S",
        "DEC": "+44D29M054.55S",
        "APPMAG": 3.0,
        "DIST": "144.51LY",
        "SPEC": "K1III"
    },
    {
        "NAME": "Pherkad",
        "RA": "15H20M043.74S",
        "DEC": "+71D50M002.46S",
        "APPMAG": 3.0,
        "DIST": "486.80LY",
        "SPEC": "A3II-III"
    },
    {
        "NAME": "Aldhanab",
        "RA": "21H53M055.71S",
        "DEC": "-37D21M053.47S",
        "APPMAG": 3.0,
        "DIST": "211.10LY",
        "SPEC": "B8III"
    },
    {
        "NAME": "Xamidimura",
        "RA": "16H51M052.23S",
        "DEC": "-38D02M050.57S",
        "APPMAG": 3.0,
        "DIST": "501.01LY",
        "SPEC": "B1.5IV + B"
    },
    {
        "NAME": "39Del Per",
        "RA": "03H42M055.50S",
        "DEC": "+47D47M015.18S",
        "APPMAG": 3.01,
        "DIST": "516.07LY",
        "SPEC": "B5III SB"
    },
    {
        "NAME": "2Eps Crv",
        "RA": "12H10M007.49S",
        "DEC": "-22D37M011.16S",
        "APPMAG": 3.02,
        "DIST": "317.89LY",
        "SPEC": "K2III"
    },
    {
        "NAME": "Furud",
        "RA": "06H20M018.79S",
        "DEC": "-30D03M048.12S",
        "APPMAG": 3.02,
        "DIST": "362.40LY",
        "SPEC": "B2.5V"
    },
    {
        "NAME": "24Omi2CMa",
        "RA": "07H03M001.47S",
        "DEC": "-23D49M059.85S",
        "APPMAG": 3.02,
        "DIST": "2764.04LY",
        "SPEC": "B3Ia"
    },
    {
        "NAME": "Almaaz",
        "RA": "05H01M058.13S",
        "DEC": "+43D49M023.91S",
        "APPMAG": 3.03,
        "DIST": "2131.74LY",
        "SPEC": "F0Ia"
    },
    {
        "NAME": "Bet Mus",
        "RA": "12H46M016.85S",
        "DEC": "-68D06M029.23S",
        "APPMAG": 3.04,
        "DIST": "341.52LY",
        "SPEC": "B2V"
    },
    {
        "NAME": "Seginus",
        "RA": "14H32M004.69S",
        "DEC": "+38D18M029.71S",
        "APPMAG": 3.04,
        "DIST": "86.79LY",
        "SPEC": "A7IIIvar"
    },
    {
        "NAME": "Albireo",
        "RA": "19H30M043.28S",
        "DEC": "+27D57M034.85S",
        "APPMAG": 3.05,
        "DIST": "434.30LY",
        "SPEC": "K3II+..."
    },
    {
        "NAME": "Dabih",
        "RA": "20H21M000.67S",
        "DEC": "-14D46M052.92S",
        "APPMAG": 3.05,
        "DIST": "326.81LY",
        "SPEC": "A5:n"
    },
    {
        "NAME": "Tania Australis",
        "RA": "10H22M019.76S",
        "DEC": "+41D29M058.26S",
        "APPMAG": 3.06,
        "DIST": "230.34LY",
        "SPEC": "M0III SB"
    },
    {
        "NAME": "Mebsuta",
        "RA": "06H43M055.93S",
        "DEC": "+25D07M052.05S",
        "APPMAG": 3.06,
        "DIST": "844.96LY",
        "SPEC": "A3mA6-A9"
    },
    {
        "NAME": "Altais",
        "RA": "19H12M033.21S",
        "DEC": "+67D39M041.55S",
        "APPMAG": 3.07,
        "DIST": "97.42LY",
        "SPEC": "G9III"
    },
    {
        "NAME": "Eta Sgr",
        "RA": "18H17M037.65S",
        "DEC": "-36D45M042.07S",
        "APPMAG": 3.1,
        "DIST": "145.93LY",
        "SPEC": "M2III"
    },
    {
        "NAME": "16Zet Hya",
        "RA": "08H55M023.63S",
        "DEC": "+05D56M044.03S",
        "APPMAG": 3.11,
        "DIST": "167.17LY",
        "SPEC": "G8III-IV"
    },
    {
        "NAME": "Lam Cen",
        "RA": "11H35M046.91S",
        "DEC": "-63D01M011.43S",
        "APPMAG": 3.11,
        "DIST": "419.76LY",
        "SPEC": "B9II:"
    },
    {
        "NAME": "Alp Ind",
        "RA": "20H37M034.02S",
        "DEC": "-47D17M029.41S",
        "APPMAG": 3.11,
        "DIST": "98.33LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "Nu  Hya",
        "RA": "10H49M037.48S",
        "DEC": "-16D11M037.13S",
        "APPMAG": 3.11,
        "DIST": "143.74LY",
        "SPEC": "K0/K1III"
    },
    {
        "NAME": "Talitha",
        "RA": "08H59M012.58S",
        "DEC": "+48D02M030.57S",
        "APPMAG": 3.12,
        "DIST": "47.32LY",
        "SPEC": "A7IV"
    },
    {
        "NAME": "Zet Ara",
        "RA": "16H58M037.22S",
        "DEC": "-55D59M024.51S",
        "APPMAG": 3.12,
        "DIST": "486.08LY",
        "SPEC": "K5III"
    },
    {
        "NAME": "Wazn",
        "RA": "05H50M057.58S",
        "DEC": "-35D46M005.91S",
        "APPMAG": 3.12,
        "DIST": "87.18LY",
        "SPEC": "K1.5III"
    },
    {
        "NAME": "Sarin",
        "RA": "17H15M001.91S",
        "DEC": "+24D50M021.13S",
        "APPMAG": 3.12,
        "DIST": "75.13LY",
        "SPEC": "A3IVv SB"
    },
    {
        "NAME": "Kap Cen",
        "RA": "14H59M009.69S",
        "DEC": "-42D06M015.10S",
        "APPMAG": 3.13,
        "DIST": "383.26LY",
        "SPEC": "B2IV"
    },
    {
        "NAME": "40Alp Lyn",
        "RA": "09H21M003.33S",
        "DEC": "+34D23M033.22S",
        "APPMAG": 3.14,
        "DIST": "203.09LY",
        "SPEC": "M0IIIvar"
    },
    {
        "NAME": "67Pi  Her",
        "RA": "17H15M002.84S",
        "DEC": "+36D48M032.98S",
        "APPMAG": 3.16,
        "DIST": "376.62LY",
        "SPEC": "K3IIvar"
    },
    {
        "NAME": "HIP 46701.0",
        "RA": "09H31M013.34S",
        "DEC": "-57D02M003.76S",
        "APPMAG": 3.16,
        "DIST": "238.94LY",
        "SPEC": "K5III"
    },
    {
        "NAME": "Nu  Pup",
        "RA": "06H37M045.67S",
        "DEC": "-43D11M045.36S",
        "APPMAG": 3.17,
        "DIST": "371.48LY",
        "SPEC": "B8III SB"
    },
    {
        "NAME": "Aldhibah",
        "RA": "17H08M047.21S",
        "DEC": "+65D42M052.86S",
        "APPMAG": 3.17,
        "DIST": "328.46LY",
        "SPEC": "B6III"
    },
    {
        "NAME": "25The UMa",
        "RA": "09H32M051.77S",
        "DEC": "+51D40M038.28S",
        "APPMAG": 3.17,
        "DIST": "43.96LY",
        "SPEC": "F6IV"
    },
    {
        "NAME": "27Phi Sgr",
        "RA": "18H45M039.38S",
        "DEC": "-26D59M026.80S",
        "APPMAG": 3.17,
        "DIST": "239.29LY",
        "SPEC": "B8.5III"
    },
    {
        "NAME": "Alp Cir",
        "RA": "14H42M030.57S",
        "DEC": "-64D58M030.50S",
        "APPMAG": 3.18,
        "DIST": "54.04LY",
        "SPEC": "F1Vp"
    },
    {
        "NAME": "Haedus",
        "RA": "05H06M030.89S",
        "DEC": "+41D14M004.11S",
        "APPMAG": 3.18,
        "DIST": "243.40LY",
        "SPEC": "B3V"
    },
    {
        "NAME": "2Eps Lep",
        "RA": "05H05M027.66S",
        "DEC": "-22D22M015.72S",
        "APPMAG": 3.19,
        "DIST": "213.31LY",
        "SPEC": "K4III"
    },
    {
        "NAME": "Tabit",
        "RA": "04H49M050.41S",
        "DEC": "+06D57M040.59S",
        "APPMAG": 3.19,
        "DIST": "26.32LY",
        "SPEC": "F6V"
    },
    {
        "NAME": "Fuyue",
        "RA": "17H49M051.47S",
        "DEC": "-37D02M035.89S",
        "APPMAG": 3.19,
        "DIST": "125.83LY",
        "SPEC": "K0/K1III"
    },
    {
        "NAME": "27Kap Oph",
        "RA": "16H57M040.10S",
        "DEC": "+09D22M030.12S",
        "APPMAG": 3.19,
        "DIST": "91.46LY",
        "SPEC": "K2IIIvar"
    },
    {
        "NAME": "64Zet Cyg",
        "RA": "21H12M056.19S",
        "DEC": "+30D13M036.90S",
        "APPMAG": 3.21,
        "DIST": "143.11LY",
        "SPEC": "G8II SB"
    },
    {
        "NAME": "Errai",
        "RA": "23H39M020.95S",
        "DEC": "+77D37M056.19S",
        "APPMAG": 3.21,
        "DIST": "46.00LY",
        "SPEC": "K1IV"
    },
    {
        "NAME": "Del Lup",
        "RA": "15H21M022.32S",
        "DEC": "-40D38M051.06S",
        "APPMAG": 3.22,
        "DIST": "883.89LY",
        "SPEC": "B1.5IV"
    },
    {
        "NAME": "Alfirk",
        "RA": "21H28M039.58S",
        "DEC": "+70D33M038.58S",
        "APPMAG": 3.23,
        "DIST": "685.20LY",
        "SPEC": "B2IIIv SB"
    },
    {
        "NAME": "58Eta Ser",
        "RA": "18H21M018.60S",
        "DEC": "-02D53M055.77S",
        "APPMAG": 3.23,
        "DIST": "60.48LY",
        "SPEC": "K0III-IV"
    },
    {
        "NAME": "Yed Posterior",
        "RA": "16H18M019.29S",
        "DEC": "-04D41M033.04S",
        "APPMAG": 3.23,
        "DIST": "106.45LY",
        "SPEC": "G8III"
    },
    {
        "NAME": "65The Aql",
        "RA": "20H11M018.29S",
        "DEC": "-00D49M017.26S",
        "APPMAG": 3.24,
        "DIST": "286.35LY",
        "SPEC": "B9.5III"
    },
    {
        "NAME": "Alp Pic",
        "RA": "06H48M011.50S",
        "DEC": "-61D56M029.01S",
        "APPMAG": 3.24,
        "DIST": "96.55LY",
        "SPEC": "A7IV"
    },
    {
        "NAME": "Brachium",
        "RA": "15H04M004.22S",
        "DEC": "-25D16M055.07S",
        "APPMAG": 3.25,
        "DIST": "288.38LY",
        "SPEC": "M3/M4III"
    },
    {
        "NAME": "49Pi  Hya",
        "RA": "14H06M022.29S",
        "DEC": "-26D40M056.50S",
        "APPMAG": 3.25,
        "DIST": "100.98LY",
        "SPEC": "K2III"
    },
    {
        "NAME": "Sulafat",
        "RA": "18H58M056.62S",
        "DEC": "+32D41M022.41S",
        "APPMAG": 3.25,
        "DIST": "620.07LY",
        "SPEC": "B9III"
    },
    {
        "NAME": "Sig Pup",
        "RA": "07H29M013.84S",
        "DEC": "-43D18M005.16S",
        "APPMAG": 3.25,
        "DIST": "193.68LY",
        "SPEC": "K5III SB"
    },
    {
        "NAME": "Gam Hyi",
        "RA": "03H47M014.26S",
        "DEC": "-74D14M020.26S",
        "APPMAG": 3.26,
        "DIST": "214.01LY",
        "SPEC": "M2III"
    },
    {
        "NAME": "42The Oph",
        "RA": "17H22M000.58S",
        "DEC": "-24D59M058.36S",
        "APPMAG": 3.27,
        "DIST": "436.04LY",
        "SPEC": "B2IV"
    },
    {
        "NAME": "Skat",
        "RA": "22H54M039.01S",
        "DEC": "-15D49M014.95S",
        "APPMAG": 3.27,
        "DIST": "160.59LY",
        "SPEC": "A3V"
    },
    {
        "NAME": "31Del And",
        "RA": "00H39M019.66S",
        "DEC": "+30D51M039.69S",
        "APPMAG": 3.27,
        "DIST": "105.52LY",
        "SPEC": "K3III..."
    },
    {
        "NAME": "Edasich",
        "RA": "15H24M055.78S",
        "DEC": "+58D57M057.83S",
        "APPMAG": 3.29,
        "DIST": "101.20LY",
        "SPEC": "K2III"
    },
    {
        "NAME": "Ome Car",
        "RA": "10H13M044.26S",
        "DEC": "-70D02M016.45S",
        "APPMAG": 3.29,
        "DIST": "341.88LY",
        "SPEC": "B8III"
    },
    {
        "NAME": "5Mu  Lep",
        "RA": "05H12M055.90S",
        "DEC": "-16D12M019.68S",
        "APPMAG": 3.29,
        "DIST": "185.95LY",
        "SPEC": "B9IV: HgMn"
    },
    {
        "NAME": "HIP 51576.0",
        "RA": "10H32M001.47S",
        "DEC": "-61D41M007.20S",
        "APPMAG": 3.3,
        "DIST": "483.19LY",
        "SPEC": "B4Vne"
    },
    {
        "NAME": "Alp Dor",
        "RA": "04H33M059.75S",
        "DEC": "-55D02M041.91S",
        "APPMAG": 3.3,
        "DIST": "168.64LY",
        "SPEC": "A0V:"
    },
    {
        "NAME": "Propus",
        "RA": "06H14M052.66S",
        "DEC": "+22D30M024.48S",
        "APPMAG": 3.31,
        "DIST": "384.62LY",
        "SPEC": "M3III"
    },
    {
        "NAME": "Gam Ara",
        "RA": "17H25M023.66S",
        "DEC": "-56D22M039.82S",
        "APPMAG": 3.31,
        "DIST": "1113.16LY",
        "SPEC": "B1Ib"
    },
    {
        "NAME": "Bet Phe",
        "RA": "01H06M005.07S",
        "DEC": "-46D43M006.29S",
        "APPMAG": 3.32,
        "DIST": "326156.38LY",
        "SPEC": "G8IIIvar"
    },
    {
        "NAME": "25Rho Per",
        "RA": "03H05M010.57S",
        "DEC": "+38D50M024.99S",
        "APPMAG": 3.32,
        "DIST": "307.69LY",
        "SPEC": "M3IIIvar"
    },
    {
        "NAME": "40Tau Sgr",
        "RA": "19H06M056.41S",
        "DEC": "-27D40M013.52S",
        "APPMAG": 3.32,
        "DIST": "121.61LY",
        "SPEC": "K1/K2III"
    },
    {
        "NAME": "Megrez",
        "RA": "12H15M025.51S",
        "DEC": "+57D01M057.42S",
        "APPMAG": 3.32,
        "DIST": "80.51LY",
        "SPEC": "A3Vvar"
    },
    {
        "NAME": "Eta Sco",
        "RA": "17H12M009.19S",
        "DEC": "-43D14M021.08S",
        "APPMAG": 3.32,
        "DIST": "73.48LY",
        "SPEC": "F3p"
    },
    {
        "NAME": "64Nu  Oph",
        "RA": "17H59M001.59S",
        "DEC": "-09D46M025.08S",
        "APPMAG": 3.32,
        "DIST": "150.72LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "Alp Ret",
        "RA": "04H14M025.45S",
        "DEC": "-62D28M025.89S",
        "APPMAG": 3.33,
        "DIST": "161.62LY",
        "SPEC": "G7III"
    },
    {
        "NAME": "Chertan",
        "RA": "11H14M014.41S",
        "DEC": "+15D25M046.45S",
        "APPMAG": 3.33,
        "DIST": "165.06LY",
        "SPEC": "A2V"
    },
    {
        "NAME": "Azmidi",
        "RA": "07H49M017.66S",
        "DEC": "-24D51M035.23S",
        "APPMAG": 3.34,
        "DIST": "1199.10LY",
        "SPEC": "G6Ia"
    },
    {
        "NAME": "Alzirr",
        "RA": "06H45M017.37S",
        "DEC": "+12D53M044.13S",
        "APPMAG": 3.35,
        "DIST": "58.70LY",
        "SPEC": "F5IV"
    },
    {
        "NAME": "Segin",
        "RA": "01H54M023.70S",
        "DEC": "+63D40M012.36S",
        "APPMAG": 3.35,
        "DIST": "411.81LY",
        "SPEC": "B2pvar"
    },
    {
        "NAME": "Muscida",
        "RA": "08H30M015.95S",
        "DEC": "+60D43M005.41S",
        "APPMAG": 3.35,
        "DIST": "179.11LY",
        "SPEC": "G4II-III"
    },
    {
        "NAME": "28Eta Ori",
        "RA": "05H24M028.62S",
        "DEC": "-02D23M049.73S",
        "APPMAG": 3.35,
        "DIST": "976.52LY",
        "SPEC": "B1V + B2"
    },
    {
        "NAME": "30Del Aql",
        "RA": "19H25M029.90S",
        "DEC": "+03D06M053.19S",
        "APPMAG": 3.36,
        "DIST": "50.64LY",
        "SPEC": "F0IV"
    },
    {
        "NAME": "Eps Lup",
        "RA": "15H22M040.88S",
        "DEC": "-44D41M022.64S",
        "APPMAG": 3.37,
        "DIST": "512.02LY",
        "SPEC": "B2IV-V"
    },
    {
        "NAME": "Ashlesha",
        "RA": "08H46M046.51S",
        "DEC": "+06D25M007.71S",
        "APPMAG": 3.38,
        "DIST": "129.27LY",
        "SPEC": "G0III-IV"
    },
    {
        "NAME": "Heze",
        "RA": "13H34M041.59S",
        "DEC": "-00D35M044.95S",
        "APPMAG": 3.38,
        "DIST": "74.08LY",
        "SPEC": "A3V"
    },
    {
        "NAME": "Meissa",
        "RA": "05H35M008.28S",
        "DEC": "+09D56M002.97S",
        "APPMAG": 3.39,
        "DIST": "1098.17LY",
        "SPEC": "O..."
    },
    {
        "NAME": "21Zet Cep",
        "RA": "22H10M051.27S",
        "DEC": "+58D12M004.54S",
        "APPMAG": 3.39,
        "DIST": "836.30LY",
        "SPEC": "K1Ibv SB"
    },
    {
        "NAME": "Minelauva",
        "RA": "12H55M036.21S",
        "DEC": "+03D23M050.89S",
        "APPMAG": 3.39,
        "DIST": "198.39LY",
        "SPEC": "M3III"
    },
    {
        "NAME": "HIP 50371.0",
        "RA": "10H17M004.99S",
        "DEC": "-61D19M056.29S",
        "APPMAG": 3.39,
        "DIST": "657.57LY",
        "SPEC": "K3II"
    },
    {
        "NAME": "Chamukuy",
        "RA": "04H28M039.74S",
        "DEC": "+15D52M015.18S",
        "APPMAG": 3.4,
        "DIST": "150.37LY",
        "SPEC": "A7III"
    },
    {
        "NAME": "Gl 656.1B",
        "RA": "17H10M022.02S",
        "DEC": "-15D43M036.92S",
        "APPMAG": 3.4,
        "DIST": "84.13LY",
        "SPEC": "A3 V"
    },
    {
        "NAME": "35Lam Tau",
        "RA": "04H00M040.82S",
        "DEC": "+12D29M025.25S",
        "APPMAG": 3.41,
        "DIST": "483.91LY",
        "SPEC": "B3V + A"
    },
    {
        "NAME": "Homam",
        "RA": "22H41M027.72S",
        "DEC": "+10D49M052.91S",
        "APPMAG": 3.41,
        "DIST": "204.36LY",
        "SPEC": "B8.5V"
    },
    {
        "NAME": "3Eta Cep",
        "RA": "20H45M017.32S",
        "DEC": "+61D50M019.62S",
        "APPMAG": 3.41,
        "DIST": "46.53LY",
        "SPEC": "K0IV"
    },
    {
        "NAME": "Gam Phe",
        "RA": "01H28M021.93S",
        "DEC": "-43D19M005.64S",
        "APPMAG": 3.41,
        "DIST": "233.64LY",
        "SPEC": "K5II-III"
    },
    {
        "NAME": "Nu  Cen",
        "RA": "13H49M030.28S",
        "DEC": "-41D41M015.75S",
        "APPMAG": 3.41,
        "DIST": "436.62LY",
        "SPEC": "B2IV"
    },
    {
        "NAME": "Zet Lup",
        "RA": "15H12M017.14S",
        "DEC": "-52D05M057.29S",
        "APPMAG": 3.41,
        "DIST": "117.32LY",
        "SPEC": "G8III"
    },
    {
        "NAME": "Eta Lup",
        "RA": "16H00M007.33S",
        "DEC": "-38D23M048.14S",
        "APPMAG": 3.42,
        "DIST": "441.95LY",
        "SPEC": "B2.5IV"
    },
    {
        "NAME": "Mothallah",
        "RA": "01H53M004.91S",
        "DEC": "+29D34M043.78S",
        "APPMAG": 3.42,
        "DIST": "63.33LY",
        "SPEC": "F6IV"
    },
    {
        "NAME": "86Mu  Her",
        "RA": "17H46M027.55S",
        "DEC": "+27D43M014.43S",
        "APPMAG": 3.42,
        "DIST": "27.11LY",
        "SPEC": "G5IV"
    },
    {
        "NAME": "Bet Pav",
        "RA": "20H44M057.53S",
        "DEC": "-66D12M011.56S",
        "APPMAG": 3.42,
        "DIST": "135.11LY",
        "SPEC": "A5IV"
    },
    {
        "NAME": "HIP 45080.0",
        "RA": "09H10M058.09S",
        "DEC": "-58D58M000.83S",
        "APPMAG": 3.43,
        "DIST": "446.79LY",
        "SPEC": "B2IV"
    },
    {
        "NAME": "16Lam Aql",
        "RA": "19H06M014.94S",
        "DEC": "-04D52M057.19S",
        "APPMAG": 3.43,
        "DIST": "123.68LY",
        "SPEC": "B9Vn"
    },
    {
        "NAME": "Adhafera",
        "RA": "10H16M041.42S",
        "DEC": "+23D25M002.32S",
        "APPMAG": 3.43,
        "DIST": "274.08LY",
        "SPEC": "F0III"
    },
    {
        "NAME": "Tania Borealis",
        "RA": "10H17M005.83S",
        "DEC": "+42D54M051.71S",
        "APPMAG": 3.45,
        "DIST": "137.50LY",
        "SPEC": "A2IV"
    },
    {
        "NAME": "31Eta Cet",
        "RA": "01H08M035.39S",
        "DEC": "-10D10M056.15S",
        "APPMAG": 3.46,
        "DIST": "123.92LY",
        "SPEC": "K2III"
    },
    {
        "NAME": "Achird",
        "RA": "00H49M005.74S",
        "DEC": "+57D48M054.67S",
        "APPMAG": 3.46,
        "DIST": "19.42LY",
        "SPEC": "G0V SB"
    },
    {
        "NAME": "Chi Car",
        "RA": "07H56M046.73S",
        "DEC": "-52D58M056.50S",
        "APPMAG": 3.46,
        "DIST": "454.89LY",
        "SPEC": "B3IVp"
    },
    {
        "NAME": "49Del Boo",
        "RA": "15H15M030.15S",
        "DEC": "+33D18M053.40S",
        "APPMAG": 3.46,
        "DIST": "121.79LY",
        "SPEC": "G8III"
    },
    {
        "NAME": "Mu  Cen",
        "RA": "13H49M036.99S",
        "DEC": "-42D28M025.44S",
        "APPMAG": 3.47,
        "DIST": "505.67LY",
        "SPEC": "B2IV-Ve"
    },
    {
        "NAME": "Kaffaljidhma",
        "RA": "02H43M018.04S",
        "DEC": "+03D14M008.94S",
        "APPMAG": 3.47,
        "DIST": "79.61LY",
        "SPEC": "A3V"
    },
    {
        "NAME": "30Eta Leo",
        "RA": "10H07M019.95S",
        "DEC": "+16D45M045.59S",
        "APPMAG": 3.48,
        "DIST": "1269.09LY",
        "SPEC": "A0Ib"
    },
    {
        "NAME": "44Eta Her",
        "RA": "16H42M053.76S",
        "DEC": "+38D55M020.11S",
        "APPMAG": 3.48,
        "DIST": "108.65LY",
        "SPEC": "G8III-IV"
    },
    {
        "NAME": "Eps Gru",
        "RA": "22H48M033.26S",
        "DEC": "-51D19M000.71S",
        "APPMAG": 3.49,
        "DIST": "128.92LY",
        "SPEC": "A3V"
    },
    {
        "NAME": "Alula Borealis",
        "RA": "11H18M028.74S",
        "DEC": "+33D05M039.50S",
        "APPMAG": 3.49,
        "DIST": "399.21LY",
        "SPEC": "K3III SB"
    },
    {
        "NAME": "Alp Tel",
        "RA": "18H26M058.42S",
        "DEC": "-45D58M006.45S",
        "APPMAG": 3.49,
        "DIST": "277.82LY",
        "SPEC": "B3IV"
    },
    {
        "NAME": "Nekkar",
        "RA": "15H01M056.77S",
        "DEC": "+40D23M026.04S",
        "APPMAG": 3.49,
        "DIST": "225.25LY",
        "SPEC": "G8III"
    },
    {
        "NAME": "52Tau Cet",
        "RA": "01H44M004.12S",
        "DEC": "-15D56M014.93S",
        "APPMAG": 3.49,
        "DIST": "11.91LY",
        "SPEC": "G8V"
    },
    {
        "NAME": "Nganurganity",
        "RA": "07H01M043.15S",
        "DEC": "-27D56M005.39S",
        "APPMAG": 3.49,
        "DIST": "1120.81LY",
        "SPEC": "K4III"
    },
    {
        "NAME": "13Kap CMa",
        "RA": "06H49M050.46S",
        "DEC": "-32D30M030.52S",
        "APPMAG": 3.5,
        "DIST": "658.90LY",
        "SPEC": "B1.5IVne"
    },
    {
        "NAME": "Wasat",
        "RA": "07H20M007.38S",
        "DEC": "+21D58M056.35S",
        "APPMAG": 3.5,
        "DIST": "60.47LY",
        "SPEC": "F0IV..."
    },
    {
        "NAME": "32Iot Cep",
        "RA": "22H49M040.87S",
        "DEC": "+66D12M001.47S",
        "APPMAG": 3.5,
        "DIST": "115.29LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "12Gam Sge",
        "RA": "19H58M045.43S",
        "DEC": "+19D29M031.73S",
        "APPMAG": 3.51,
        "DIST": "258.44LY",
        "SPEC": "K5III"
    },
    {
        "NAME": "Sadalbari",
        "RA": "22H50M000.19S",
        "DEC": "+24D36M005.68S",
        "APPMAG": 3.51,
        "DIST": "106.10LY",
        "SPEC": "M2III"
    },
    {
        "NAME": "Sheliak",
        "RA": "18H50M004.79S",
        "DEC": "+33D21M045.60S",
        "APPMAG": 3.52,
        "DIST": "962.11LY",
        "SPEC": "A8:V comp SB"
    },
    {
        "NAME": "Subra",
        "RA": "09H41M009.03S",
        "DEC": "+09D53M032.31S",
        "APPMAG": 3.52,
        "DIST": "130.31LY",
        "SPEC": "A5V+..."
    },
    {
        "NAME": "Phi Vel",
        "RA": "09H56M051.75S",
        "DEC": "-54D34M004.04S",
        "APPMAG": 3.52,
        "DIST": "1591.01LY",
        "SPEC": "B5Ib"
    },
    {
        "NAME": "Biham",
        "RA": "22H10M011.99S",
        "DEC": "+06D11M052.31S",
        "APPMAG": 3.52,
        "DIST": "92.29LY",
        "SPEC": "A2V"
    },
    {
        "NAME": "29Gam Vir",
        "RA": "12H41M039.02S",
        "DEC": "-01D26M057.25S",
        "APPMAG": 3.52,
        "DIST": "38.58LY",
        "SPEC": "F0 V"
    },
    {
        "NAME": "Rana",
        "RA": "03H43M014.90S",
        "DEC": "-09D45M048.22S",
        "APPMAG": 3.52,
        "DIST": "29.49LY",
        "SPEC": "K0IV"
    },
    {
        "NAME": "37Xi 2Sgr",
        "RA": "18H57M043.80S",
        "DEC": "-21D06M023.95S",
        "APPMAG": 3.52,
        "DIST": "365.24LY",
        "SPEC": "G8/K0II/III"
    },
    {
        "NAME": "Ain",
        "RA": "04H28M036.99S",
        "DEC": "+19D10M049.55S",
        "APPMAG": 3.53,
        "DIST": "146.65LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "Tarf",
        "RA": "08H16M030.92S",
        "DEC": "+09D11M007.96S",
        "APPMAG": 3.53,
        "DIST": "303.40LY",
        "SPEC": "K4III"
    },
    {
        "NAME": "Xi  Hya",
        "RA": "11H33M000.14S",
        "DEC": "-31D51M027.45S",
        "APPMAG": 3.54,
        "DIST": "129.63LY",
        "SPEC": "G8III"
    },
    {
        "NAME": "55Xi  Ser",
        "RA": "17H37M035.20S",
        "DEC": "-15D23M054.81S",
        "APPMAG": 3.54,
        "DIST": "105.28LY",
        "SPEC": "F0IIIp"
    },
    {
        "NAME": "32Mu  Ser",
        "RA": "15H49M037.21S",
        "DEC": "-03D25M048.75S",
        "APPMAG": 3.54,
        "DIST": "169.61LY",
        "SPEC": "A0V"
    },
    {
        "NAME": "Iot Lup",
        "RA": "14H19M024.23S",
        "DEC": "-46D03M029.13S",
        "APPMAG": 3.55,
        "DIST": "337.99LY",
        "SPEC": "B2.5IV"
    },
    {
        "NAME": "14Zet Lep",
        "RA": "05H46M057.34S",
        "DEC": "-14D49M019.02S",
        "APPMAG": 3.55,
        "DIST": "70.47LY",
        "SPEC": "A2Vann"
    },
    {
        "NAME": "Del Pav",
        "RA": "20H08M042.57S",
        "DEC": "-66D10M055.44S",
        "APPMAG": 3.55,
        "DIST": "19.92LY",
        "SPEC": "G5IV-Vvar"
    },
    {
        "NAME": "41Ups4Eri",
        "RA": "04H17M053.65S",
        "DEC": "-33D47M054.05S",
        "APPMAG": 3.55,
        "DIST": "177.94LY",
        "SPEC": "B9V"
    },
    {
        "NAME": "44Chi Dra",
        "RA": "18H21M002.65S",
        "DEC": "+72D43M058.23S",
        "APPMAG": 3.55,
        "DIST": "26.28LY",
        "SPEC": "F7Vvar"
    },
    {
        "NAME": "12Del Crt",
        "RA": "11H19M020.45S",
        "DEC": "-14D46M042.75S",
        "APPMAG": 3.56,
        "DIST": "185.74LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "8Iot Cet",
        "RA": "00H19M025.68S",
        "DEC": "-08D49M026.12S",
        "APPMAG": 3.56,
        "DIST": "274.54LY",
        "SPEC": "K2III"
    },
    {
        "NAME": "Phi Eri",
        "RA": "02H16M030.55S",
        "DEC": "-51D30M043.79S",
        "APPMAG": 3.56,
        "DIST": "153.70LY",
        "SPEC": "B8IV-V"
    },
    {
        "NAME": "Pipirima",
        "RA": "16H52M020.15S",
        "DEC": "-38D01M003.13S",
        "APPMAG": 3.56,
        "DIST": "474.06LY",
        "SPEC": "B2IV"
    },
    {
        "NAME": "25Rho Boo",
        "RA": "14H31M049.80S",
        "DEC": "+30D22M017.17S",
        "APPMAG": 3.57,
        "DIST": "160.12LY",
        "SPEC": "K3III"
    },
    {
        "NAME": "77Kap Gem",
        "RA": "07H44M026.85S",
        "DEC": "+24D23M052.77S",
        "APPMAG": 3.57,
        "DIST": "141.38LY",
        "SPEC": "G8III"
    },
    {
        "NAME": "Phi1Lup",
        "RA": "15H21M048.38S",
        "DEC": "-36D15M040.95S",
        "APPMAG": 3.57,
        "DIST": "275.01LY",
        "SPEC": "K5III"
    },
    {
        "NAME": "Alkaphrah",
        "RA": "09H03M037.54S",
        "DEC": "+47D09M023.49S",
        "APPMAG": 3.57,
        "DIST": "358.41LY",
        "SPEC": "A1Vn"
    },
    {
        "NAME": "54Lam Gem",
        "RA": "07H18M005.58S",
        "DEC": "+16D32M025.38S",
        "APPMAG": 3.58,
        "DIST": "100.88LY",
        "SPEC": "A3V..."
    },
    {
        "NAME": "Algedi",
        "RA": "20H18M003.25S",
        "DEC": "-12D32M041.47S",
        "APPMAG": 3.58,
        "DIST": "105.83LY",
        "SPEC": "G6/G8III"
    },
    {
        "NAME": "Ginan",
        "RA": "12H21M021.71S",
        "DEC": "-60D24M004.13S",
        "APPMAG": 3.59,
        "DIST": "229.85LY",
        "SPEC": "K3/K4III"
    },
    {
        "NAME": "20Tau Ori",
        "RA": "05H17M036.39S",
        "DEC": "-06D50M039.87S",
        "APPMAG": 3.59,
        "DIST": "494.18LY",
        "SPEC": "B5III"
    },
    {
        "NAME": "Nembus",
        "RA": "01H37M059.54S",
        "DEC": "+48D37M041.57S",
        "APPMAG": 3.59,
        "DIST": "177.16LY",
        "SPEC": "K3III"
    },
    {
        "NAME": "13Gam Lep",
        "RA": "05H44M027.81S",
        "DEC": "-22D26M054.18S",
        "APPMAG": 3.59,
        "DIST": "29.12LY",
        "SPEC": "F7V"
    },
    {
        "NAME": "Zavijava",
        "RA": "11H50M041.72S",
        "DEC": "+01D45M052.98S",
        "APPMAG": 3.59,
        "DIST": "35.65LY",
        "SPEC": "F8V"
    },
    {
        "NAME": "Del Ara",
        "RA": "17H31M005.94S",
        "DEC": "-60D41M001.85S",
        "APPMAG": 3.6,
        "DIST": "197.91LY",
        "SPEC": "B8V"
    },
    {
        "NAME": "39Ups Lib",
        "RA": "15H37M001.45S",
        "DEC": "-28D08M006.28S",
        "APPMAG": 3.6,
        "DIST": "223.70LY",
        "SPEC": "K3III"
    },
    {
        "NAME": "Psi Vel",
        "RA": "09H30M042.03S",
        "DEC": "-40D28M000.37S",
        "APPMAG": 3.6,
        "DIST": "61.37LY",
        "SPEC": "F2IV"
    },
    {
        "NAME": "HIP 42536.0",
        "RA": "08H40M017.59S",
        "DEC": "-52D55M018.79S",
        "APPMAG": 3.6,
        "DIST": "493.43LY",
        "SPEC": "B3IV"
    },
    {
        "NAME": "34The Gem",
        "RA": "06H52M047.34S",
        "DEC": "+33D57M040.51S",
        "APPMAG": 3.6,
        "DIST": "189.08LY",
        "SPEC": "A3III"
    },
    {
        "NAME": "45The Cet",
        "RA": "01H24M001.40S",
        "DEC": "-08D10M059.73S",
        "APPMAG": 3.6,
        "DIST": "113.80LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "Bharani",
        "RA": "02H49M059.03S",
        "DEC": "+27D15M037.83S",
        "APPMAG": 3.61,
        "DIST": "165.65LY",
        "SPEC": "B8Vn"
    },
    {
        "NAME": "Eta Pav",
        "RA": "17H45M044.00S",
        "DEC": "-64D43M025.94S",
        "APPMAG": 3.61,
        "DIST": "352.22LY",
        "SPEC": "K1III"
    },
    {
        "NAME": "41Lam Hya",
        "RA": "10H10M035.28S",
        "DEC": "-12D21M014.70S",
        "APPMAG": 3.61,
        "DIST": "112.55LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "1Omi Tau",
        "RA": "03H24M048.79S",
        "DEC": "+09D01M043.93S",
        "APPMAG": 3.61,
        "DIST": "290.95LY",
        "SPEC": "G8III"
    },
    {
        "NAME": "Del Mus",
        "RA": "13H02M015.93S",
        "DEC": "-71D32M055.88S",
        "APPMAG": 3.61,
        "DIST": "90.90LY",
        "SPEC": "K2III"
    },
    {
        "NAME": "Zet2Sco",
        "RA": "16H54M035.03S",
        "DEC": "-42D21M040.73S",
        "APPMAG": 3.62,
        "DIST": "132.32LY",
        "SPEC": "K4III"
    },
    {
        "NAME": "Atlas",
        "RA": "03H49M009.74S",
        "DEC": "+24D03M012.29S",
        "APPMAG": 3.62,
        "DIST": "382.36LY",
        "SPEC": "B8III"
    },
    {
        "NAME": "Alpherg",
        "RA": "01H31M029.01S",
        "DEC": "+15D20M044.96S",
        "APPMAG": 3.62,
        "DIST": "349.58LY",
        "SPEC": "G8III"
    },
    {
        "NAME": "HIP 37819.0",
        "RA": "07H45M015.30S",
        "DEC": "-37D58M006.90S",
        "APPMAG": 3.62,
        "DIST": "1132.49LY",
        "SPEC": "K4III"
    },
    {
        "NAME": "1Omi And",
        "RA": "23H01M055.26S",
        "DEC": "+42D19M033.52S",
        "APPMAG": 3.62,
        "DIST": "686.64LY",
        "SPEC": "B6pv SB"
    },
    {
        "NAME": "Lam Mus",
        "RA": "11H45M036.51S",
        "DEC": "-66D43M043.55S",
        "APPMAG": 3.63,
        "DIST": "127.16LY",
        "SPEC": "A7III"
    },
    {
        "NAME": "Rotanev",
        "RA": "20H37M032.94S",
        "DEC": "+14D35M042.31S",
        "APPMAG": 3.64,
        "DIST": "100.88LY",
        "SPEC": "F5IV"
    },
    {
        "NAME": "The Ara",
        "RA": "18H06M037.87S",
        "DEC": "-50D05M029.32S",
        "APPMAG": 3.65,
        "DIST": "813.36LY",
        "SPEC": "B2Ib"
    },
    {
        "NAME": "Prima Hyadum",
        "RA": "04H19M047.60S",
        "DEC": "+15D37M039.51S",
        "APPMAG": 3.65,
        "DIST": "161.54LY",
        "SPEC": "G8III"
    },
    {
        "NAME": "28Bet Ser",
        "RA": "15H46M011.25S",
        "DEC": "+15D25M018.57S",
        "APPMAG": 3.65,
        "DIST": "155.09LY",
        "SPEC": "A3V"
    },
    {
        "NAME": "55Zet1Aqr",
        "RA": "22H28M049.91S",
        "DEC": "-00D01M011.90S",
        "APPMAG": 3.65,
        "DIST": "91.87LY",
        "SPEC": "F3III-IV"
    },
    {
        "NAME": "23    UMa",
        "RA": "09H31M031.63S",
        "DEC": "+63D03M042.70S",
        "APPMAG": 3.65,
        "DIST": "77.67LY",
        "SPEC": "F0IV"
    },
    {
        "NAME": "40Tau Lib",
        "RA": "15H38M039.37S",
        "DEC": "-29D46M039.91S",
        "APPMAG": 3.66,
        "DIST": "366.88LY",
        "SPEC": "B2.5V"
    },
    {
        "NAME": "Nusakan",
        "RA": "15H27M049.74S",
        "DEC": "+29D06M020.53S",
        "APPMAG": 3.66,
        "DIST": "111.81LY",
        "SPEC": "F0p"
    },
    {
        "NAME": "Thuban",
        "RA": "14H04M023.39S",
        "DEC": "+64D22M033.06S",
        "APPMAG": 3.67,
        "DIST": "303.12LY",
        "SPEC": "A0III SB"
    },
    {
        "NAME": "Bet Ind",
        "RA": "20H54M048.59S",
        "DEC": "-58D27M014.96S",
        "APPMAG": 3.67,
        "DIST": "611.93LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "Alp Pyx",
        "RA": "08H43M035.54S",
        "DEC": "-33D11M010.99S",
        "APPMAG": 3.68,
        "DIST": "879.13LY",
        "SPEC": "B1.5III"
    },
    {
        "NAME": "88    Aqr",
        "RA": "23H09M026.79S",
        "DEC": "-21D10M020.68S",
        "APPMAG": 3.68,
        "DIST": "270.67LY",
        "SPEC": "K1III"
    },
    {
        "NAME": "3Pi 4Ori",
        "RA": "04H51M012.36S",
        "DEC": "+05D36M018.37S",
        "APPMAG": 3.68,
        "DIST": "1052.12LY",
        "SPEC": "B2III SB"
    },
    {
        "NAME": "7Del Sge",
        "RA": "19H47M023.26S",
        "DEC": "+18D32M003.43S",
        "APPMAG": 3.68,
        "DIST": "594.09LY",
        "SPEC": "M2II + B6"
    },
    {
        "NAME": "HIP 47854.0",
        "RA": "09H45M014.82S",
        "DEC": "-62D30M028.45S",
        "APPMAG": 3.69,
        "DIST": "1560.56LY",
        "SPEC": "G5Iab/Ib"
    },
    {
        "NAME": "Taiyangshou",
        "RA": "11H46M003.05S",
        "DEC": "+47D46M045.86S",
        "APPMAG": 3.69,
        "DIST": "183.65LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "Nashira",
        "RA": "21H40M005.45S",
        "DEC": "-16D39M044.31S",
        "APPMAG": 3.69,
        "DIST": "157.03LY",
        "SPEC": "A7III:mp..."
    },
    {
        "NAME": "Chi Eri",
        "RA": "01H55M057.23S",
        "DEC": "-51D36M032.03S",
        "APPMAG": 3.69,
        "DIST": "58.22LY",
        "SPEC": "G5IV"
    },
    {
        "NAME": "Saclateni",
        "RA": "05H02M028.68S",
        "DEC": "+41D04M033.01S",
        "APPMAG": 3.69,
        "DIST": "785.92LY",
        "SPEC": "K4II comp"
    },
    {
        "NAME": "Fulu",
        "RA": "00H36M058.28S",
        "DEC": "+53D53M048.87S",
        "APPMAG": 3.69,
        "DIST": "593.01LY",
        "SPEC": "B2IV"
    },
    {
        "NAME": "6Gam Psc",
        "RA": "23H17M009.94S",
        "DEC": "+03D16M056.24S",
        "APPMAG": 3.7,
        "DIST": "137.97LY",
        "SPEC": "G7III"
    },
    {
        "NAME": "16Tau4Eri",
        "RA": "03H19M031.00S",
        "DEC": "-21D45M028.31S",
        "APPMAG": 3.7,
        "DIST": "304.53LY",
        "SPEC": "M3/M4III"
    },
    {
        "NAME": "92Xi  Her",
        "RA": "17H57M045.88S",
        "DEC": "+29D14M052.37S",
        "APPMAG": 3.7,
        "DIST": "136.81LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "HIP 38414.0",
        "RA": "07H52M013.04S",
        "DEC": "-40D34M032.83S",
        "APPMAG": 3.71,
        "DIST": "352.60LY",
        "SPEC": "G5III..."
    },
    {
        "NAME": "37Eps Ser",
        "RA": "15H50M048.97S",
        "DEC": "+04D28M039.83S",
        "APPMAG": 3.71,
        "DIST": "70.44LY",
        "SPEC": "A2m"
    },
    {
        "NAME": "8Pi 5Ori",
        "RA": "04H54M015.09S",
        "DEC": "+02D26M026.42S",
        "APPMAG": 3.71,
        "DIST": "1342.21LY",
        "SPEC": "B2III SB"
    },
    {
        "NAME": "Alshain",
        "RA": "19H55M018.79S",
        "DEC": "+06D24M024.35S",
        "APPMAG": 3.71,
        "DIST": "44.68LY",
        "SPEC": "G8IVvar"
    },
    {
        "NAME": "16Eta Lep",
        "RA": "05H56M024.30S",
        "DEC": "-14D10M003.72S",
        "APPMAG": 3.71,
        "DIST": "48.53LY",
        "SPEC": "F1V"
    },
    {
        "NAME": "72    Oph",
        "RA": "18H07M020.99S",
        "DEC": "+09D33M049.85S",
        "APPMAG": 3.71,
        "DIST": "86.86LY",
        "SPEC": "A4IVs"
    },
    {
        "NAME": "Electra",
        "RA": "03H44M052.54S",
        "DEC": "+24D06M048.02S",
        "APPMAG": 3.72,
        "DIST": "404.66LY",
        "SPEC": "B6III"
    },
    {
        "NAME": "Ran",
        "RA": "03H32M055.85S",
        "DEC": "-09D27M029.74S",
        "APPMAG": 3.72,
        "DIST": "10.49LY",
        "SPEC": "K2V"
    },
    {
        "NAME": "33Del Aur",
        "RA": "05H59M031.60S",
        "DEC": "+54D17M004.76S",
        "APPMAG": 3.72,
        "DIST": "126.03LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "62Xi  Cyg",
        "RA": "21H04M055.86S",
        "DEC": "+43D55M040.27S",
        "APPMAG": 3.72,
        "DIST": "842.78LY",
        "SPEC": "K5Ibv SB"
    },
    {
        "NAME": "109    Vir",
        "RA": "14H46M014.92S",
        "DEC": "+01D53M034.39S",
        "APPMAG": 3.73,
        "DIST": "134.50LY",
        "SPEC": "A0V"
    },
    {
        "NAME": "Grumium",
        "RA": "17H53M031.68S",
        "DEC": "+56D52M021.51S",
        "APPMAG": 3.73,
        "DIST": "112.55LY",
        "SPEC": "K2III"
    },
    {
        "NAME": "73Lam Aqr",
        "RA": "22H52M036.88S",
        "DEC": "-07D34M046.56S",
        "APPMAG": 3.73,
        "DIST": "385.07LY",
        "SPEC": "M2IIIvar"
    },
    {
        "NAME": "2Xi  Tau",
        "RA": "03H27M010.15S",
        "DEC": "+09D43M057.65S",
        "APPMAG": 3.73,
        "DIST": "209.07LY",
        "SPEC": "B9Vn"
    },
    {
        "NAME": "Nu  Oct",
        "RA": "21H41M028.51S",
        "DEC": "-77D23M024.17S",
        "APPMAG": 3.73,
        "DIST": "69.14LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "Baten Kaitos",
        "RA": "01H51M027.63S",
        "DEC": "-10D20M006.14S",
        "APPMAG": 3.74,
        "DIST": "234.98LY",
        "SPEC": "K2III"
    },
    {
        "NAME": "20Gam Her",
        "RA": "16H21M055.22S",
        "DEC": "+19D09M011.27S",
        "APPMAG": 3.74,
        "DIST": "192.65LY",
        "SPEC": "A9III"
    },
    {
        "NAME": "65Tau Cyg",
        "RA": "21H14M047.46S",
        "DEC": "+38D02M043.14S",
        "APPMAG": 3.74,
        "DIST": "66.35LY",
        "SPEC": "F1IV"
    },
    {
        "NAME": "HIP 44511.0",
        "RA": "09H04M009.29S",
        "DEC": "-47D05M051.85S",
        "APPMAG": 3.75,
        "DIST": "299.50LY",
        "SPEC": "K2III"
    },
    {
        "NAME": "62Gam Oph",
        "RA": "17H47M053.56S",
        "DEC": "+02D42M026.19S",
        "APPMAG": 3.75,
        "DIST": "102.79LY",
        "SPEC": "A0V"
    },
    {
        "NAME": "7Alp Lac",
        "RA": "22H31M017.45S",
        "DEC": "+50D16M056.97S",
        "APPMAG": 3.76,
        "DIST": "102.60LY",
        "SPEC": "A1V"
    },
    {
        "NAME": "Bet Dor",
        "RA": "05H33M037.52S",
        "DEC": "-62D29M023.37S",
        "APPMAG": 3.76,
        "DIST": "1006.66LY",
        "SPEC": "F6Ia"
    },
    {
        "NAME": "15Del Lep",
        "RA": "05H51M019.29S",
        "DEC": "-20D52M044.72S",
        "APPMAG": 3.76,
        "DIST": "113.72LY",
        "SPEC": "G8III/IV"
    },
    {
        "NAME": "39Omi Sgr",
        "RA": "19H04M040.98S",
        "DEC": "-21D44M029.39S",
        "APPMAG": 3.76,
        "DIST": "142.05LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "11Bet Mon",
        "RA": "06H28M049.07S",
        "DEC": "-07D01M059.02S",
        "APPMAG": 3.76,
        "DIST": "676.67LY",
        "SPEC": "B3Ve"
    },
    {
        "NAME": "10Iot2Cyg",
        "RA": "19H29M042.35S",
        "DEC": "+51D43M047.20S",
        "APPMAG": 3.76,
        "DIST": "121.34LY",
        "SPEC": "A5Vn"
    },
    {
        "NAME": "Miram",
        "RA": "02H50M041.80S",
        "DEC": "+55D53M043.79S",
        "APPMAG": 3.77,
        "DIST": "879.13LY",
        "SPEC": "K3Ib comp SB"
    },
    {
        "NAME": "34Zet Cap",
        "RA": "21H26M040.03S",
        "DEC": "-22D24M040.80S",
        "APPMAG": 3.77,
        "DIST": "385.53LY",
        "SPEC": "G4Ibp..."
    },
    {
        "NAME": "Secunda Hyadum",
        "RA": "04H22M056.09S",
        "DEC": "+17D32M033.05S",
        "APPMAG": 3.77,
        "DIST": "155.61LY",
        "SPEC": "G8III"
    },
    {
        "NAME": "Eta Ara",
        "RA": "16H49M047.14S",
        "DEC": "-59D02M028.96S",
        "APPMAG": 3.77,
        "DIST": "299.23LY",
        "SPEC": "K5III"
    },
    {
        "NAME": "Sualocin",
        "RA": "20H39M038.29S",
        "DEC": "+15D54M043.46S",
        "APPMAG": 3.77,
        "DIST": "253.82LY",
        "SPEC": "B9V"
    },
    {
        "NAME": "24Iot Peg",
        "RA": "22H07M000.65S",
        "DEC": "+25D20M042.40S",
        "APPMAG": 3.77,
        "DIST": "38.25LY",
        "SPEC": "F5V"
    },
    {
        "NAME": "HIP 42570.0",
        "RA": "08H40M037.57S",
        "DEC": "-46D38M055.48S",
        "APPMAG": 3.77,
        "DIST": "326156.38LY",
        "SPEC": "F3Ia"
    },
    {
        "NAME": "41Nu  Per",
        "RA": "03H45M011.64S",
        "DEC": "+42D34M042.78S",
        "APPMAG": 3.77,
        "DIST": "556.58LY",
        "SPEC": "F5IIvar"
    },
    {
        "NAME": "Bet Vol",
        "RA": "08H25M044.22S",
        "DEC": "-66D08M012.80S",
        "APPMAG": 3.77,
        "DIST": "107.54LY",
        "SPEC": "K2IIIvar"
    },
    {
        "NAME": "48Sig Ori",
        "RA": "05H38M044.77S",
        "DEC": "-02D36M000.25S",
        "APPMAG": 3.77,
        "DIST": "1072.88LY",
        "SPEC": "O9.5V..."
    },
    {
        "NAME": "60Iot Gem",
        "RA": "07H25M043.60S",
        "DEC": "+27D47M053.09S",
        "APPMAG": 3.78,
        "DIST": "120.35LY",
        "SPEC": "G9III+..."
    },
    {
        "NAME": "29Ups UMa",
        "RA": "09H50M059.52S",
        "DEC": "+59D02M019.45S",
        "APPMAG": 3.78,
        "DIST": "116.24LY",
        "SPEC": "F0IV"
    },
    {
        "NAME": "Albali",
        "RA": "20H47M040.55S",
        "DEC": "-09D29M044.79S",
        "APPMAG": 3.78,
        "DIST": "207.74LY",
        "SPEC": "A1V"
    },
    {
        "NAME": "Gam2Vol",
        "RA": "07H08M044.84S",
        "DEC": "-70D29M056.16S",
        "APPMAG": 3.78,
        "DIST": "139.80LY",
        "SPEC": "G8IIIvar"
    },
    {
        "NAME": "30Zet Boo",
        "RA": "14H41M008.95S",
        "DEC": "+13D43M041.88S",
        "APPMAG": 3.78,
        "DIST": "175.73LY",
        "SPEC": "A3IVn"
    },
    {
        "NAME": "Gl 404.1",
        "RA": "10H53M029.61S",
        "DEC": "-58D51M011.42S",
        "APPMAG": 3.78,
        "DIST": "95.01LY",
        "SPEC": "K0III-IV..."
    },
    {
        "NAME": "Praecipua",
        "RA": "10H53M018.69S",
        "DEC": "+34D12M053.54S",
        "APPMAG": 3.79,
        "DIST": "94.87LY",
        "SPEC": "K0III-IV"
    },
    {
        "NAME": "Misam",
        "RA": "03H09M029.73S",
        "DEC": "+44D51M027.16S",
        "APPMAG": 3.79,
        "DIST": "112.74LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "HIP 37229.0",
        "RA": "07H38M049.87S",
        "DEC": "-26D48M013.81S",
        "APPMAG": 3.8,
        "DIST": "346.61LY",
        "SPEC": "B5IV"
    },
    {
        "NAME": "13Del Ser",
        "RA": "15H34M048.15S",
        "DEC": "+10D32M019.92S",
        "APPMAG": 3.8,
        "DIST": "228.08LY",
        "SPEC": "F0IV"
    },
    {
        "NAME": "Dalim",
        "RA": "03H12M004.50S",
        "DEC": "-28D59M015.42S",
        "APPMAG": 3.8,
        "DIST": "46.43LY",
        "SPEC": "F8V"
    },
    {
        "NAME": "1Kap Cyg",
        "RA": "19H17M006.14S",
        "DEC": "+53D22M006.45S",
        "APPMAG": 3.8,
        "DIST": "124.16LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "31    Cyg",
        "RA": "20H13M037.91S",
        "DEC": "+46D44M028.78S",
        "APPMAG": 3.8,
        "DIST": "883.89LY",
        "SPEC": "K2II+..."
    },
    {
        "NAME": "Theemin",
        "RA": "04H35M033.04S",
        "DEC": "-30D33M044.43S",
        "APPMAG": 3.81,
        "DIST": "213.87LY",
        "SPEC": "G8III"
    },
    {
        "NAME": "8Gam CrB",
        "RA": "15H42M044.57S",
        "DEC": "+26D17M044.29S",
        "APPMAG": 3.81,
        "DIST": "146.06LY",
        "SPEC": "A1Vs"
    },
    {
        "NAME": "16Lam And",
        "RA": "23H37M033.80S",
        "DEC": "+46D27M029.35S",
        "APPMAG": 3.81,
        "DIST": "86.13LY",
        "SPEC": "G8III-IV"
    },
    {
        "NAME": "HIP 51232.0",
        "RA": "10H27M052.74S",
        "DEC": "-58D44M021.85S",
        "APPMAG": 3.81,
        "DIST": "1342.21LY",
        "SPEC": "F2II"
    },
    {
        "NAME": "85Iot Her",
        "RA": "17H39M027.89S",
        "DEC": "+46D00M022.80S",
        "APPMAG": 3.82,
        "DIST": "454.89LY",
        "SPEC": "B3V SB"
    },
    {
        "NAME": "Marfik",
        "RA": "16H30M054.82S",
        "DEC": "+01D59M002.12S",
        "APPMAG": 3.82,
        "DIST": "173.12LY",
        "SPEC": "A2V"
    },
    {
        "NAME": "38    Lyn",
        "RA": "09H18M050.65S",
        "DEC": "+36D48M009.35S",
        "APPMAG": 3.82,
        "DIST": "124.82LY",
        "SPEC": "A1V"
    },
    {
        "NAME": "Giausar",
        "RA": "11H31M024.27S",
        "DEC": "+69D19M051.87S",
        "APPMAG": 3.82,
        "DIST": "333.15LY",
        "SPEC": "M0IIIvar"
    },
    {
        "NAME": "Alrescha",
        "RA": "02H02M002.82S",
        "DEC": "+02D45M049.53S",
        "APPMAG": 3.82,
        "DIST": "150.58LY",
        "SPEC": "A2"
    },
    {
        "NAME": "42Mu  Hya",
        "RA": "10H26M005.43S",
        "DEC": "-16D50M010.64S",
        "APPMAG": 3.83,
        "DIST": "234.14LY",
        "SPEC": "K4III"
    },
    {
        "NAME": "Alp Aps",
        "RA": "14H47M051.72S",
        "DEC": "-79D02M041.10S",
        "APPMAG": 3.83,
        "DIST": "446.79LY",
        "SPEC": "K5III"
    },
    {
        "NAME": "Phi Cen",
        "RA": "13H58M016.27S",
        "DEC": "-42D06M002.71S",
        "APPMAG": 3.83,
        "DIST": "525.21LY",
        "SPEC": "B2IV"
    },
    {
        "NAME": "63Eps Dra",
        "RA": "19H48M010.26S",
        "DEC": "+70D16M004.55S",
        "APPMAG": 3.84,
        "DIST": "147.98LY",
        "SPEC": "G8III"
    },
    {
        "NAME": "Gam Mus",
        "RA": "12H32M028.08S",
        "DEC": "-72D07M058.76S",
        "APPMAG": 3.84,
        "DIST": "324.86LY",
        "SPEC": "B5V"
    },
    {
        "NAME": "Bet Ret",
        "RA": "03H44M011.73S",
        "DEC": "-64D48M024.85S",
        "APPMAG": 3.84,
        "DIST": "97.39LY",
        "SPEC": "K0IV SB"
    },
    {
        "NAME": "77The1Tau",
        "RA": "04H28M034.49S",
        "DEC": "+15D57M043.85S",
        "APPMAG": 3.84,
        "DIST": "154.36LY",
        "SPEC": "G7III"
    },
    {
        "NAME": "47Rho Leo",
        "RA": "10H32M048.67S",
        "DEC": "+09D18M023.71S",
        "APPMAG": 3.84,
        "DIST": "326156.38LY",
        "SPEC": "B1Ib SB"
    },
    {
        "NAME": "Atik",
        "RA": "03H44M019.13S",
        "DEC": "+32D17M017.69S",
        "APPMAG": 3.84,
        "DIST": "1120.81LY",
        "SPEC": "B1III"
    },
    {
        "NAME": "HIP 43783.0",
        "RA": "08H55M002.85S",
        "DEC": "-60D38M040.59S",
        "APPMAG": 3.84,
        "DIST": "319.76LY",
        "SPEC": "B8III"
    },
    {
        "NAME": "103Omi Her",
        "RA": "18H07M032.55S",
        "DEC": "+28D45M044.96S",
        "APPMAG": 3.84,
        "DIST": "337.99LY",
        "SPEC": "B9.5V"
    },
    {
        "NAME": "HIP 51986.0",
        "RA": "10H37M018.18S",
        "DEC": "-48D13M032.23S",
        "APPMAG": 3.84,
        "DIST": "87.54LY",
        "SPEC": "A3m+..."
    },
    {
        "NAME": "Polis",
        "RA": "18H13M045.81S",
        "DEC": "-21D03M031.80S",
        "APPMAG": 3.84,
        "DIST": "326156.38LY",
        "SPEC": "B2III:"
    },
    {
        "NAME": "Tau Cen",
        "RA": "12H37M042.22S",
        "DEC": "-48D32M028.69S",
        "APPMAG": 3.85,
        "DIST": "131.25LY",
        "SPEC": "A2V"
    },
    {
        "NAME": "41Gam Ser",
        "RA": "15H56M027.18S",
        "DEC": "+15D39M041.82S",
        "APPMAG": 3.85,
        "DIST": "36.70LY",
        "SPEC": "F6V"
    },
    {
        "NAME": "Alp Hor",
        "RA": "04H14M000.11S",
        "DEC": "-42D17M039.72S",
        "APPMAG": 3.85,
        "DIST": "115.01LY",
        "SPEC": "K1III"
    },
    {
        "NAME": "5Kap Dra",
        "RA": "12H33M029.01S",
        "DEC": "+69D47M017.66S",
        "APPMAG": 3.85,
        "DIST": "490.46LY",
        "SPEC": "B6IIIp"
    },
    {
        "NAME": "Bet Pic",
        "RA": "05H47M017.08S",
        "DEC": "-51D03M059.45S",
        "APPMAG": 3.85,
        "DIST": "63.41LY",
        "SPEC": "A3V"
    },
    {
        "NAME": "HIP 50191.0",
        "RA": "10H14M044.19S",
        "DEC": "-42D07M018.99S",
        "APPMAG": 3.85,
        "DIST": "101.35LY",
        "SPEC": "A2V"
    },
    {
        "NAME": "Alp Sct",
        "RA": "18H35M012.43S",
        "DEC": "-08D14M038.66S",
        "APPMAG": 3.85,
        "DIST": "199.12LY",
        "SPEC": "K2III"
    },
    {
        "NAME": "109    Her",
        "RA": "18H23M041.88S",
        "DEC": "+21D46M011.11S",
        "APPMAG": 3.85,
        "DIST": "118.95LY",
        "SPEC": "K2III"
    },
    {
        "NAME": "Del Col",
        "RA": "06H22M006.83S",
        "DEC": "-33D26M011.04S",
        "APPMAG": 3.85,
        "DIST": "233.97LY",
        "SPEC": "G7II"
    },
    {
        "NAME": "Sceptrum",
        "RA": "04H38M010.82S",
        "DEC": "-14D18M014.47S",
        "APPMAG": 3.86,
        "DIST": "109.85LY",
        "SPEC": "K1III"
    },
    {
        "NAME": "37Mu  And",
        "RA": "00H56M045.19S",
        "DEC": "+38D29M057.64S",
        "APPMAG": 3.86,
        "DIST": "129.74LY",
        "SPEC": "A5V"
    },
    {
        "NAME": "Gam Aps",
        "RA": "16H33M027.39S",
        "DEC": "-78D53M049.73S",
        "APPMAG": 3.86,
        "DIST": "156.28LY",
        "SPEC": "K0IV SB"
    },
    {
        "NAME": "Sadachbia",
        "RA": "22H21M039.38S",
        "DEC": "-01D23M014.39S",
        "APPMAG": 3.86,
        "DIST": "163.73LY",
        "SPEC": "A0V"
    },
    {
        "NAME": "Eps Col",
        "RA": "05H31M012.75S",
        "DEC": "-35D28M013.87S",
        "APPMAG": 3.86,
        "DIST": "263.24LY",
        "SPEC": "K1II/III"
    },
    {
        "NAME": "Del TrA",
        "RA": "16H15M026.27S",
        "DEC": "-63D41M008.46S",
        "APPMAG": 3.86,
        "DIST": "607.37LY",
        "SPEC": "G5II"
    },
    {
        "NAME": "91The Her",
        "RA": "17H56M015.18S",
        "DEC": "+37D15M001.94S",
        "APPMAG": 3.86,
        "DIST": "753.25LY",
        "SPEC": "K1IIvar"
    },
    {
        "NAME": "Iklil",
        "RA": "15H56M053.08S",
        "DEC": "-29D12M050.66S",
        "APPMAG": 3.87,
        "DIST": "472.01LY",
        "SPEC": "B2IV/V"
    },
    {
        "NAME": "Ups1Cen",
        "RA": "13H58M040.75S",
        "DEC": "-44D48M012.90S",
        "APPMAG": 3.87,
        "DIST": "427.47LY",
        "SPEC": "B2IV-V"
    },
    {
        "NAME": "HIP 43023.0",
        "RA": "08H46M001.65S",
        "DEC": "-46D02M029.50S",
        "APPMAG": 3.87,
        "DIST": "1853.16LY",
        "SPEC": "A1III"
    },
    {
        "NAME": "107Mu  Vir",
        "RA": "14H43M003.62S",
        "DEC": "-05D39M029.55S",
        "APPMAG": 3.87,
        "DIST": "59.59LY",
        "SPEC": "F2III"
    },
    {
        "NAME": "Maia",
        "RA": "03H45M049.60S",
        "DEC": "+24D22M003.89S",
        "APPMAG": 3.87,
        "DIST": "383.26LY",
        "SPEC": "B8III"
    },
    {
        "NAME": "55Eta Aql",
        "RA": "19H52M028.37S",
        "DEC": "+01D00M020.38S",
        "APPMAG": 3.87,
        "DIST": "1382.02LY",
        "SPEC": "F6Ibv SB"
    },
    {
        "NAME": "Rasalas",
        "RA": "09H52M045.83S",
        "DEC": "+26D00M025.02S",
        "APPMAG": 3.88,
        "DIST": "124.11LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "Iot Gru",
        "RA": "23H10M021.50S",
        "DEC": "-45D14M048.16S",
        "APPMAG": 3.88,
        "DIST": "183.23LY",
        "SPEC": "K0III SB"
    },
    {
        "NAME": "Kap1Lup",
        "RA": "15H11M056.10S",
        "DEC": "-48D44M016.15S",
        "APPMAG": 3.88,
        "DIST": "180.00LY",
        "SPEC": "B9V"
    },
    {
        "NAME": "Eps Phe",
        "RA": "00H09M024.61S",
        "DEC": "-45D44M050.73S",
        "APPMAG": 3.88,
        "DIST": "144.19LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "Mesarthim",
        "RA": "01H53M031.81S",
        "DEC": "+19D17M037.87S",
        "APPMAG": 3.88,
        "DIST": "164.06LY",
        "SPEC": "A1p Si"
    },
    {
        "NAME": "Zaniah",
        "RA": "12H19M054.36S",
        "DEC": "-00D40M000.49S",
        "APPMAG": 3.89,
        "DIST": "265.38LY",
        "SPEC": "A2IV"
    },
    {
        "NAME": "22The Hya",
        "RA": "09H14M021.86S",
        "DEC": "+02D18M051.41S",
        "APPMAG": 3.89,
        "DIST": "113.49LY",
        "SPEC": "B9.5V"
    },
    {
        "NAME": "21Eta Cyg",
        "RA": "19H56M018.38S",
        "DEC": "+35D05M000.33S",
        "APPMAG": 3.89,
        "DIST": "134.94LY",
        "SPEC": "K0IIIvar"
    },
    {
        "NAME": "16Omi1CMa",
        "RA": "06H54M007.95S",
        "DEC": "-24D11M003.16S",
        "APPMAG": 3.89,
        "DIST": "326156.38LY",
        "SPEC": "K3Iab"
    },
    {
        "NAME": "Azha",
        "RA": "02H56M025.65S",
        "DEC": "-08D53M053.32S",
        "APPMAG": 3.89,
        "DIST": "136.52LY",
        "SPEC": "K1III-IV"
    },
    {
        "NAME": "HIP 65936.0",
        "RA": "13H31M002.66S",
        "DEC": "-39D24M026.31S",
        "APPMAG": 3.9,
        "DIST": "905.99LY",
        "SPEC": "G8II/III"
    },
    {
        "NAME": "Pi  Cen",
        "RA": "11H21M000.42S",
        "DEC": "-54D29M027.67S",
        "APPMAG": 3.9,
        "DIST": "357.63LY",
        "SPEC": "B5Vn"
    },
    {
        "NAME": "Ukdah",
        "RA": "09H39M051.36S",
        "DEC": "-01D08M034.12S",
        "APPMAG": 3.9,
        "DIST": "263.24LY",
        "SPEC": "K3IIIvar"
    },
    {
        "NAME": "Sig Cen",
        "RA": "12H28M002.39S",
        "DEC": "-50D13M050.29S",
        "APPMAG": 3.91,
        "DIST": "411.81LY",
        "SPEC": "B3V"
    },
    {
        "NAME": "38Nu  Tau",
        "RA": "04H03M009.38S",
        "DEC": "+05D59M021.50S",
        "APPMAG": 3.91,
        "DIST": "116.94LY",
        "SPEC": "A1V"
    },
    {
        "NAME": "22Tau Her",
        "RA": "16H19M044.44S",
        "DEC": "+46D18M048.12S",
        "APPMAG": 3.91,
        "DIST": "307.40LY",
        "SPEC": "B5IV"
    },
    {
        "NAME": "HIP 41307.0",
        "RA": "08H25M039.63S",
        "DEC": "-03D54M023.13S",
        "APPMAG": 3.91,
        "DIST": "122.34LY",
        "SPEC": "A0V"
    },
    {
        "NAME": "Zubenelhakrabi",
        "RA": "15H35M031.58S",
        "DEC": "-14D47M022.33S",
        "APPMAG": 3.91,
        "DIST": "163.16LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "Pi  Lup",
        "RA": "15H05M007.09S",
        "DEC": "-47D03M004.48S",
        "APPMAG": 3.91,
        "DIST": "443.15LY",
        "SPEC": "B5"
    },
    {
        "NAME": "44Rho1Sgr",
        "RA": "19H21M040.36S",
        "DEC": "-17D50M049.91S",
        "APPMAG": 3.92,
        "DIST": "126.96LY",
        "SPEC": "F0III/IV"
    },
    {
        "NAME": "Kitalpha",
        "RA": "21H15M049.43S",
        "DEC": "+05D14M052.24S",
        "APPMAG": 3.92,
        "DIST": "190.29LY",
        "SPEC": "G0III+..."
    },
    {
        "NAME": "58Eps Her",
        "RA": "17H00M017.38S",
        "DEC": "+30D55M035.06S",
        "APPMAG": 3.92,
        "DIST": "155.02LY",
        "SPEC": "A0V"
    },
    {
        "NAME": "9Ome1Sco",
        "RA": "16H06M048.43S",
        "DEC": "-20D40M009.09S",
        "APPMAG": 3.93,
        "DIST": "471.32LY",
        "SPEC": "B1V"
    },
    {
        "NAME": "18Tau Per",
        "RA": "02H54M015.46S",
        "DEC": "+52D45M044.92S",
        "APPMAG": 3.93,
        "DIST": "254.21LY",
        "SPEC": "G4III..."
    },
    {
        "NAME": "Kap Phe",
        "RA": "00H26M012.18S",
        "DEC": "-43D40M047.38S",
        "APPMAG": 3.93,
        "DIST": "77.66LY",
        "SPEC": "A7V"
    },
    {
        "NAME": "Zet Vol",
        "RA": "07H41M049.21S",
        "DEC": "-72D36M021.95S",
        "APPMAG": 3.93,
        "DIST": "141.01LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "Del Phe",
        "RA": "01H31M015.06S",
        "DEC": "-49D04M021.73S",
        "APPMAG": 3.93,
        "DIST": "142.12LY",
        "SPEC": "K0III-IV"
    },
    {
        "NAME": "48Nu  Eri",
        "RA": "04H36M019.14S",
        "DEC": "-03D21M008.85S",
        "APPMAG": 3.93,
        "DIST": "675.27LY",
        "SPEC": "B2III SB"
    },
    {
        "NAME": "HIP 54463.0",
        "RA": "11H08M035.39S",
        "DEC": "-58D58M030.13S",
        "APPMAG": 3.93,
        "DIST": "326156.38LY",
        "SPEC": "G0Ia0"
    },
    {
        "NAME": "67    Oph",
        "RA": "18H00M038.71S",
        "DEC": "+02D55M053.64S",
        "APPMAG": 3.93,
        "DIST": "1230.78LY",
        "SPEC": "B5Ib"
    },
    {
        "NAME": "58Nu  Cyg",
        "RA": "20H57M010.41S",
        "DEC": "+41D10M001.69S",
        "APPMAG": 3.94,
        "DIST": "374.46LY",
        "SPEC": "A1Vn"
    },
    {
        "NAME": "26Alp Mon",
        "RA": "07H41M014.83S",
        "DEC": "-09D33M004.07S",
        "APPMAG": 3.94,
        "DIST": "147.78LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "3    Pup",
        "RA": "07H43M048.47S",
        "DEC": "-28D57M017.37S",
        "APPMAG": 3.94,
        "DIST": "326156.38LY",
        "SPEC": "A2Iab"
    },
    {
        "NAME": "Asellus Australis",
        "RA": "08H44M041.10S",
        "DEC": "+18D09M015.51S",
        "APPMAG": 3.94,
        "DIST": "130.57LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "Wurren",
        "RA": "01H08M023.07S",
        "DEC": "-55D14M044.74S",
        "APPMAG": 3.94,
        "DIST": "298.68LY",
        "SPEC": "B6V + B0V"
    },
    {
        "NAME": "50    Cas",
        "RA": "02H03M026.16S",
        "DEC": "+72D25M016.66S",
        "APPMAG": 3.95,
        "DIST": "157.11LY",
        "SPEC": "A2V"
    },
    {
        "NAME": "79Zet UMa",
        "RA": "13H23M056.39S",
        "DEC": "+54D55M013.70S",
        "APPMAG": 3.95,
        "DIST": "78.78LY",
        "SPEC": "A1 m"
    },
    {
        "NAME": "7Nu 2CMa",
        "RA": "06H36M041.04S",
        "DEC": "-19D15M021.16S",
        "APPMAG": 3.95,
        "DIST": "64.42LY",
        "SPEC": "K1III+..."
    },
    {
        "NAME": "98    Aqr",
        "RA": "23H22M058.23S",
        "DEC": "-20D06M002.09S",
        "APPMAG": 3.96,
        "DIST": "163.40LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "Rukbat",
        "RA": "19H23M053.17S",
        "DEC": "-40D36M057.38S",
        "APPMAG": 3.96,
        "DIST": "181.80LY",
        "SPEC": "B8V"
    },
    {
        "NAME": "48    Per",
        "RA": "04H08M039.69S",
        "DEC": "+47D42M045.05S",
        "APPMAG": 3.96,
        "DIST": "476.84LY",
        "SPEC": "B3Ve"
    },
    {
        "NAME": "Arkab Prior",
        "RA": "19H22M038.29S",
        "DEC": "-44D27M032.27S",
        "APPMAG": 3.96,
        "DIST": "313.61LY",
        "SPEC": "B9V"
    },
    {
        "NAME": "Gl 332A",
        "RA": "09H00M038.47S",
        "DEC": "+41D46M058.48S",
        "APPMAG": 3.96,
        "DIST": "52.41LY",
        "SPEC": "F5V"
    },
    {
        "NAME": "Eta Col",
        "RA": "05H59M008.80S",
        "DEC": "-42D48M054.49S",
        "APPMAG": 3.96,
        "DIST": "472.01LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "HIP 45101.0",
        "RA": "09H11M016.75S",
        "DEC": "-62D19M001.12S",
        "APPMAG": 3.96,
        "DIST": "542.69LY",
        "SPEC": "B3IV"
    },
    {
        "NAME": "32    Cyg",
        "RA": "20H15M028.32S",
        "DEC": "+47D42M051.15S",
        "APPMAG": 3.96,
        "DIST": "1058.95LY",
        "SPEC": "K3Ib-II comp"
    },
    {
        "NAME": "Rho Cen",
        "RA": "12H11M039.13S",
        "DEC": "-52D22M006.46S",
        "APPMAG": 3.97,
        "DIST": "378.81LY",
        "SPEC": "B3V"
    },
    {
        "NAME": "Del Vol",
        "RA": "07H16M049.83S",
        "DEC": "-67D57M025.75S",
        "APPMAG": 3.97,
        "DIST": "737.91LY",
        "SPEC": "F6II"
    },
    {
        "NAME": "5Chi Lup",
        "RA": "15H50M057.54S",
        "DEC": "-33D37M037.79S",
        "APPMAG": 3.97,
        "DIST": "195.19LY",
        "SPEC": "B9.5III-IV"
    },
    {
        "NAME": "Bet Pyx",
        "RA": "08H40M006.14S",
        "DEC": "-35D18M030.07S",
        "APPMAG": 3.97,
        "DIST": "416.02LY",
        "SPEC": "G5II/III"
    },
    {
        "NAME": "Beemim",
        "RA": "04H24M002.21S",
        "DEC": "-34D01M000.65S",
        "APPMAG": 3.97,
        "DIST": "296.24LY",
        "SPEC": "K4III"
    },
    {
        "NAME": "Del1Gru",
        "RA": "22H29M016.17S",
        "DEC": "-43D29M044.03S",
        "APPMAG": 3.97,
        "DIST": "309.45LY",
        "SPEC": "G6/G8III"
    },
    {
        "NAME": "Eps Pav",
        "RA": "20H00M035.44S",
        "DEC": "-72D54M037.81S",
        "APPMAG": 3.97,
        "DIST": "105.08LY",
        "SPEC": "A0V"
    },
    {
        "NAME": "32Nu  Aur",
        "RA": "05H51M029.40S",
        "DEC": "+39D08M054.53S",
        "APPMAG": 3.97,
        "DIST": "230.34LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "47Lam Peg",
        "RA": "22H46M031.88S",
        "DEC": "+23D33M056.35S",
        "APPMAG": 3.97,
        "DIST": "365.24LY",
        "SPEC": "G8II-III"
    },
    {
        "NAME": "73Rho Cyg",
        "RA": "21H33M058.86S",
        "DEC": "+45D35M030.61S",
        "APPMAG": 3.98,
        "DIST": "123.59LY",
        "SPEC": "G8III"
    },
    {
        "NAME": "Menkib",
        "RA": "03H58M057.90S",
        "DEC": "+35D47M027.72S",
        "APPMAG": 3.98,
        "DIST": "1244.87LY",
        "SPEC": "O7.5Iab:"
    },
    {
        "NAME": "59Ups Cet",
        "RA": "02H00M000.30S",
        "DEC": "-21D04M040.19S",
        "APPMAG": 3.99,
        "DIST": "292.78LY",
        "SPEC": "K5/M0III"
    },
    {
        "NAME": "5Gam Mon",
        "RA": "06H14M051.33S",
        "DEC": "-06D16M029.19S",
        "APPMAG": 3.99,
        "DIST": "497.95LY",
        "SPEC": "K3III"
    },
    {
        "NAME": "Alcor",
        "RA": "13H25M013.49S",
        "DEC": "+54D59M016.65S",
        "APPMAG": 3.99,
        "DIST": "81.72LY",
        "SPEC": "A5V SB"
    },
    {
        "NAME": "Gl 391",
        "RA": "10H24M023.73S",
        "DEC": "-74D01M053.80S",
        "APPMAG": 3.99,
        "DIST": "52.91LY",
        "SPEC": "F2IV"
    },
    {
        "NAME": "Gam Tuc",
        "RA": "23H17M025.79S",
        "DEC": "-58D14M008.64S",
        "APPMAG": 3.99,
        "DIST": "75.20LY",
        "SPEC": "F1III"
    },
    {
        "NAME": "Jabbah",
        "RA": "16H11M059.73S",
        "DEC": "-19D27M038.55S",
        "APPMAG": 4.0,
        "DIST": "474.06LY",
        "SPEC": "B2IV"
    },
    {
        "NAME": "Alp Vol",
        "RA": "09H02M026.80S",
        "DEC": "-66D23M045.87S",
        "APPMAG": 4.0,
        "DIST": "124.92LY",
        "SPEC": "Am"
    },
    {
        "NAME": "78Iot Leo",
        "RA": "11H23M055.45S",
        "DEC": "+10D31M046.23S",
        "APPMAG": 4.0,
        "DIST": "77.21LY",
        "SPEC": "F2IV SB"
    },
    {
        "NAME": "28Ome CMa",
        "RA": "07H14M048.66S",
        "DEC": "-26D46M021.60S",
        "APPMAG": 4.01,
        "DIST": "911.05LY",
        "SPEC": "B2IV/Ve"
    },
    {
        "NAME": "Zet Pav",
        "RA": "18H43M002.14S",
        "DEC": "-71D25M041.21S",
        "APPMAG": 4.01,
        "DIST": "218.46LY",
        "SPEC": "K2III"
    },
    {
        "NAME": "41    Cyg",
        "RA": "20H29M023.73S",
        "DEC": "+30D22M006.80S",
        "APPMAG": 4.01,
        "DIST": "769.24LY",
        "SPEC": "F5II"
    },
    {
        "NAME": "HIP 71865.0",
        "RA": "14H41M057.60S",
        "DEC": "-37D47M036.59S",
        "APPMAG": 4.01,
        "DIST": "339.04LY",
        "SPEC": "B2.5V"
    },
    {
        "NAME": "Gam2Nor",
        "RA": "16H19M050.47S",
        "DEC": "-50D09M019.83S",
        "APPMAG": 4.01,
        "DIST": "128.76LY",
        "SPEC": "G8III"
    },
    {
        "NAME": "57Mu  Eri",
        "RA": "04H45M030.15S",
        "DEC": "-03D15M016.77S",
        "APPMAG": 4.01,
        "DIST": "521.85LY",
        "SPEC": "B5IV"
    },
    {
        "NAME": "Phi Per",
        "RA": "01H43M039.63S",
        "DEC": "+50D41M019.44S",
        "APPMAG": 4.01,
        "DIST": "718.41LY",
        "SPEC": "B2Vpe"
    },
    {
        "NAME": "Mekbuda",
        "RA": "07H04M006.53S",
        "DEC": "+20D34M013.07S",
        "APPMAG": 4.01,
        "DIST": "1376.19LY",
        "SPEC": "G3Ibv SB"
    },
    {
        "NAME": "13The Dra",
        "RA": "16H01M053.52S",
        "DEC": "+58D33M054.90S",
        "APPMAG": 4.01,
        "DIST": "68.61LY",
        "SPEC": "F8IV-V"
    },
    {
        "NAME": "12    Aql",
        "RA": "19H01M040.83S",
        "DEC": "-05D44M020.81S",
        "APPMAG": 4.02,
        "DIST": "143.93LY",
        "SPEC": "K1IIIvar"
    },
    {
        "NAME": "Alchiba",
        "RA": "12H08M024.81S",
        "DEC": "-24D43M043.95S",
        "APPMAG": 4.02,
        "DIST": "48.72LY",
        "SPEC": "F0IV/V"
    },
    {
        "NAME": "Gam Pyx",
        "RA": "08H50M031.93S",
        "DEC": "-27D42M035.44S",
        "APPMAG": 4.02,
        "DIST": "207.35LY",
        "SPEC": "K3III"
    },
    {
        "NAME": "13Eps Aql",
        "RA": "18H59M037.36S",
        "DEC": "+15D04M005.87S",
        "APPMAG": 4.02,
        "DIST": "154.94LY",
        "SPEC": "K2III"
    },
    {
        "NAME": "70    Oph",
        "RA": "18H05M027.29S",
        "DEC": "+02D30M000.36S",
        "APPMAG": 4.03,
        "DIST": "16.58LY",
        "SPEC": "K0V SB"
    },
    {
        "NAME": "28Ome Psc",
        "RA": "23H59M018.69S",
        "DEC": "+06D51M047.96S",
        "APPMAG": 4.03,
        "DIST": "104.34LY",
        "SPEC": "F4IV"
    },
    {
        "NAME": "Aldulfin",
        "RA": "20H33M012.77S",
        "DEC": "+11D18M011.75S",
        "APPMAG": 4.03,
        "DIST": "330.45LY",
        "SPEC": "B6III"
    },
    {
        "NAME": "10Bet Cam",
        "RA": "05H03M025.09S",
        "DEC": "+60D26M032.08S",
        "APPMAG": 4.03,
        "DIST": "872.08LY",
        "SPEC": "G0Ib"
    },
    {
        "NAME": "Mu 1Cru",
        "RA": "12H54M035.64S",
        "DEC": "-57D10M040.53S",
        "APPMAG": 4.03,
        "DIST": "414.43LY",
        "SPEC": "B2IV-V"
    },
    {
        "NAME": "9Gam Tri",
        "RA": "02H17M018.86S",
        "DEC": "+33D50M049.90S",
        "APPMAG": 4.03,
        "DIST": "112.31LY",
        "SPEC": "A1Vnn"
    },
    {
        "NAME": "48Iot Cnc",
        "RA": "08H46M041.82S",
        "DEC": "+28D45M035.63S",
        "APPMAG": 4.03,
        "DIST": "331.12LY",
        "SPEC": "G8Iab:"
    },
    {
        "NAME": "62Eta Aqr",
        "RA": "22H35M021.38S",
        "DEC": "-00D07M002.99S",
        "APPMAG": 4.04,
        "DIST": "167.86LY",
        "SPEC": "B9IV-Vn"
    },
    {
        "NAME": "3Nu  Vir",
        "RA": "11H45M051.56S",
        "DEC": "+06D31M045.75S",
        "APPMAG": 4.04,
        "DIST": "293.83LY",
        "SPEC": "M0III"
    },
    {
        "NAME": "Beid",
        "RA": "04H11M051.94S",
        "DEC": "-06D50M015.29S",
        "APPMAG": 4.04,
        "DIST": "121.70LY",
        "SPEC": "F2II-III"
    },
    {
        "NAME": "23The Boo",
        "RA": "14H25M011.88S",
        "DEC": "+51D51M002.68S",
        "APPMAG": 4.04,
        "DIST": "47.39LY",
        "SPEC": "F7V"
    },
    {
        "NAME": "Alp Cha",
        "RA": "08H18M031.33S",
        "DEC": "-76D55M011.00S",
        "APPMAG": 4.05,
        "DIST": "63.80LY",
        "SPEC": "F5III"
    },
    {
        "NAME": "Iot Per",
        "RA": "03H09M003.62S",
        "DEC": "+49D36M047.80S",
        "APPMAG": 4.05,
        "DIST": "34.38LY",
        "SPEC": "G0V"
    },
    {
        "NAME": "71Tau2Aqr",
        "RA": "22H49M035.50S",
        "DEC": "-13D35M033.48S",
        "APPMAG": 4.05,
        "DIST": "317.58LY",
        "SPEC": "K5III"
    },
    {
        "NAME": "77Sig Leo",
        "RA": "11H21M008.19S",
        "DEC": "+06D01M045.56S",
        "APPMAG": 4.05,
        "DIST": "220.08LY",
        "SPEC": "B9.5Vs"
    },
    {
        "NAME": "Psi Cen",
        "RA": "14H20M033.44S",
        "DEC": "-37D53M007.06S",
        "APPMAG": 4.05,
        "DIST": "258.85LY",
        "SPEC": "A0IV"
    },
    {
        "NAME": "5Ups Boo",
        "RA": "13H49M028.64S",
        "DEC": "+15D47M052.46S",
        "APPMAG": 4.05,
        "DIST": "263.45LY",
        "SPEC": "K5IIIvar"
    },
    {
        "NAME": "Rho Lup",
        "RA": "14H37M053.23S",
        "DEC": "-49D25M032.98S",
        "APPMAG": 4.05,
        "DIST": "316.04LY",
        "SPEC": "B5V"
    },
    {
        "NAME": "Gl 321.1",
        "RA": "08H44M023.95S",
        "DEC": "-42D38M057.39S",
        "APPMAG": 4.05,
        "DIST": "228.88LY",
        "SPEC": "G5III"
    },
    {
        "NAME": "Eps1Ara",
        "RA": "16H59M035.05S",
        "DEC": "-53D09M037.58S",
        "APPMAG": 4.06,
        "DIST": "360.79LY",
        "SPEC": "K4III"
    },
    {
        "NAME": "HIP 72010.0",
        "RA": "14H43M039.45S",
        "DEC": "-35D10M025.16S",
        "APPMAG": 4.06,
        "DIST": "209.48LY",
        "SPEC": "K3III"
    },
    {
        "NAME": "Eps Mus",
        "RA": "12H17M034.50S",
        "DEC": "-67D57M038.65S",
        "APPMAG": 4.06,
        "DIST": "301.44LY",
        "SPEC": "M5III"
    },
    {
        "NAME": "9Omi2Ori",
        "RA": "04H56M022.28S",
        "DEC": "+13D30M052.08S",
        "APPMAG": 4.06,
        "DIST": "185.95LY",
        "SPEC": "K2III"
    },
    {
        "NAME": "15Gam Crt",
        "RA": "11H24M052.93S",
        "DEC": "-17D41M002.44S",
        "APPMAG": 4.06,
        "DIST": "82.32LY",
        "SPEC": "A9V"
    },
    {
        "NAME": "69Ups Gem",
        "RA": "07H35M055.35S",
        "DEC": "+26D53M044.67S",
        "APPMAG": 4.06,
        "DIST": "270.89LY",
        "SPEC": "K5III"
    },
    {
        "NAME": "Zet Cru",
        "RA": "12H18M026.27S",
        "DEC": "-64D00M011.06S",
        "APPMAG": 4.06,
        "DIST": "357.63LY",
        "SPEC": "B2.5V"
    },
    {
        "NAME": "Bet Cir",
        "RA": "15H17M030.90S",
        "DEC": "-58D48M004.35S",
        "APPMAG": 4.07,
        "DIST": "99.65LY",
        "SPEC": "A3V"
    },
    {
        "NAME": "Syrma",
        "RA": "14H16M000.87S",
        "DEC": "-06D00M001.97S",
        "APPMAG": 4.07,
        "DIST": "72.53LY",
        "SPEC": "F7V"
    },
    {
        "NAME": "Lam Lup",
        "RA": "15H08M050.62S",
        "DEC": "-45D16M047.49S",
        "APPMAG": 4.07,
        "DIST": "776.56LY",
        "SPEC": "B3V"
    },
    {
        "NAME": "27Del Cep",
        "RA": "22H29M010.26S",
        "DEC": "+58D24M054.71S",
        "APPMAG": 4.07,
        "DIST": "865.14LY",
        "SPEC": "G2Ibvar"
    },
    {
        "NAME": "34Zet And",
        "RA": "00H47M020.33S",
        "DEC": "+24D16M001.84S",
        "APPMAG": 4.08,
        "DIST": "189.19LY",
        "SPEC": "K1II"
    },
    {
        "NAME": "14The CMa",
        "RA": "06H54M011.40S",
        "DEC": "-12D02M019.06S",
        "APPMAG": 4.08,
        "DIST": "260.72LY",
        "SPEC": "K4III"
    },
    {
        "NAME": "23The Cap",
        "RA": "21H05M056.82S",
        "DEC": "-17D13M058.30S",
        "APPMAG": 4.08,
        "DIST": "162.19LY",
        "SPEC": "A1V"
    },
    {
        "NAME": "1    Peg",
        "RA": "21H22M005.20S",
        "DEC": "+19D48M016.23S",
        "APPMAG": 4.08,
        "DIST": "155.83LY",
        "SPEC": "K1III"
    },
    {
        "NAME": "HIP 46974.0",
        "RA": "09H34M026.66S",
        "DEC": "-59D13M047.11S",
        "APPMAG": 4.08,
        "DIST": "1325.84LY",
        "SPEC": "B5II"
    },
    {
        "NAME": "11Tau3Eri",
        "RA": "03H02M023.51S",
        "DEC": "-23D37M028.10S",
        "APPMAG": 4.08,
        "DIST": "88.63LY",
        "SPEC": "A4V"
    },
    {
        "NAME": "13    Lyr",
        "RA": "18H55M020.10S",
        "DEC": "+43D56M045.92S",
        "APPMAG": 4.08,
        "DIST": "298.13LY",
        "SPEC": "M5IIIvar"
    },
    {
        "NAME": "82Del Cet",
        "RA": "02H39M028.96S",
        "DEC": "+00D19M042.64S",
        "APPMAG": 4.08,
        "DIST": "649.71LY",
        "SPEC": "B2IV"
    },
    {
        "NAME": "Alkes",
        "RA": "10H59M046.48S",
        "DEC": "-18D17M055.62S",
        "APPMAG": 4.08,
        "DIST": "159.18LY",
        "SPEC": "K1III"
    },
    {
        "NAME": "Del Hyi",
        "RA": "02H21M044.99S",
        "DEC": "-68D39M033.90S",
        "APPMAG": 4.08,
        "DIST": "139.68LY",
        "SPEC": "A3V"
    },
    {
        "NAME": "Gudja",
        "RA": "15H48M044.38S",
        "DEC": "+18D08M029.63S",
        "APPMAG": 4.09,
        "DIST": "381.92LY",
        "SPEC": "M1III"
    },
    {
        "NAME": "40Phi2Ori",
        "RA": "05H36M054.39S",
        "DEC": "+09D17M026.42S",
        "APPMAG": 4.09,
        "DIST": "117.49LY",
        "SPEC": "G8III-IV"
    },
    {
        "NAME": "13The Per",
        "RA": "02H44M011.88S",
        "DEC": "+49D13M042.41S",
        "APPMAG": 4.1,
        "DIST": "36.29LY",
        "SPEC": "F7V"
    },
    {
        "NAME": "Bet CrA",
        "RA": "19H10M001.75S",
        "DEC": "-39D20M026.87S",
        "APPMAG": 4.1,
        "DIST": "474.06LY",
        "SPEC": "K0II/IIICN."
    },
    {
        "NAME": "Titawin",
        "RA": "01H36M047.88S",
        "DEC": "+41D24M019.65S",
        "APPMAG": 4.1,
        "DIST": "44.00LY",
        "SPEC": "F8V"
    },
    {
        "NAME": "HIP 38164.0",
        "RA": "07H49M014.30S",
        "DEC": "-46D22M023.54S",
        "APPMAG": 4.1,
        "DIST": "1647.25LY",
        "SPEC": "B0III"
    },
    {
        "NAME": "Zet Tel",
        "RA": "18H28M049.82S",
        "DEC": "-49D04M014.12S",
        "APPMAG": 4.1,
        "DIST": "126.22LY",
        "SPEC": "G8/K0III"
    },
    {
        "NAME": "Eps TrA",
        "RA": "15H36M043.20S",
        "DEC": "-66D19M001.33S",
        "APPMAG": 4.11,
        "DIST": "201.70LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "Meridiana",
        "RA": "19H09M028.33S",
        "DEC": "-37D54M016.11S",
        "APPMAG": 4.11,
        "DIST": "125.35LY",
        "SPEC": "A0/A1V"
    },
    {
        "NAME": "Zet Gru",
        "RA": "23H00M052.84S",
        "DEC": "-52D45M014.89S",
        "APPMAG": 4.11,
        "DIST": "108.86LY",
        "SPEC": "G8III"
    },
    {
        "NAME": "HIP 42312.0",
        "RA": "08H37M038.64S",
        "DEC": "-42D59M020.69S",
        "APPMAG": 4.11,
        "DIST": "1822.10LY",
        "SPEC": "A6II"
    },
    {
        "NAME": "Muliphein",
        "RA": "07H03M045.49S",
        "DEC": "-15D37M059.83S",
        "APPMAG": 4.11,
        "DIST": "441.95LY",
        "SPEC": "B8II"
    },
    {
        "NAME": "HIP 57439.0",
        "RA": "11H46M030.84S",
        "DEC": "-61D10M042.23S",
        "APPMAG": 4.11,
        "DIST": "389.67LY",
        "SPEC": "G0II"
    },
    {
        "NAME": "Gam Cha",
        "RA": "10H35M028.20S",
        "DEC": "-78D36M028.03S",
        "APPMAG": 4.11,
        "DIST": "417.61LY",
        "SPEC": "M0III"
    },
    {
        "NAME": "Zhang",
        "RA": "09H51M028.69S",
        "DEC": "-14D50M047.77S",
        "APPMAG": 4.11,
        "DIST": "263.88LY",
        "SPEC": "G6/G8III"
    },
    {
        "NAME": "Iot Eri",
        "RA": "02H40M040.01S",
        "DEC": "-39D51M019.35S",
        "APPMAG": 4.11,
        "DIST": "150.65LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "61Mu  Ori",
        "RA": "06H02M023.00S",
        "DEC": "+09D38M050.19S",
        "APPMAG": 4.12,
        "DIST": "154.94LY",
        "SPEC": "Am..."
    },
    {
        "NAME": "9Omi Vir",
        "RA": "12H05M012.54S",
        "DEC": "+08D43M058.75S",
        "APPMAG": 4.12,
        "DIST": "163.24LY",
        "SPEC": "G8III"
    },
    {
        "NAME": "Del2Gru",
        "RA": "22H29M045.44S",
        "DEC": "-43D44M057.21S",
        "APPMAG": 4.12,
        "DIST": "330.12LY",
        "SPEC": "M4.5IIIa"
    },
    {
        "NAME": "18Ome Cap",
        "RA": "20H51M049.29S",
        "DEC": "-26D55M008.88S",
        "APPMAG": 4.12,
        "DIST": "842.78LY",
        "SPEC": "K4III"
    },
    {
        "NAME": "Eps Hyi",
        "RA": "02H39M035.28S",
        "DEC": "-68D16M001.01S",
        "APPMAG": 4.12,
        "DIST": "151.84LY",
        "SPEC": "B9III"
    },
    {
        "NAME": "51Mu  Per",
        "RA": "04H14M053.86S",
        "DEC": "+48D24M033.59S",
        "APPMAG": 4.12,
        "DIST": "900.98LY",
        "SPEC": "G0Ib..."
    },
    {
        "NAME": "Iot Sgr",
        "RA": "19H55M015.69S",
        "DEC": "-41D52M005.84S",
        "APPMAG": 4.12,
        "DIST": "181.80LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "29    Ori",
        "RA": "05H23M056.83S",
        "DEC": "-07D48M029.03S",
        "APPMAG": 4.13,
        "DIST": "157.34LY",
        "SPEC": "G8III"
    },
    {
        "NAME": "18Nu  Gem",
        "RA": "06H28M057.79S",
        "DEC": "+20D12M043.68S",
        "APPMAG": 4.13,
        "DIST": "544.50LY",
        "SPEC": "B6III"
    },
    {
        "NAME": "16Psi Cap",
        "RA": "20H46M005.74S",
        "DEC": "-25D16M015.23S",
        "APPMAG": 4.13,
        "DIST": "47.87LY",
        "SPEC": "F5V"
    },
    {
        "NAME": "17Iot Psc",
        "RA": "23H39M057.04S",
        "DEC": "+05D37M034.65S",
        "APPMAG": 4.13,
        "DIST": "44.73LY",
        "SPEC": "F7V"
    },
    {
        "NAME": "46The Lib",
        "RA": "15H53M049.53S",
        "DEC": "-16D43M045.45S",
        "APPMAG": 4.13,
        "DIST": "168.47LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "Bet Oct",
        "RA": "22H46M003.69S",
        "DEC": "-81D22M053.81S",
        "APPMAG": 4.13,
        "DIST": "149.27LY",
        "SPEC": "A9IV/V"
    },
    {
        "NAME": "10Kap Peg",
        "RA": "21H44M038.73S",
        "DEC": "+25D38M042.13S",
        "APPMAG": 4.14,
        "DIST": "111.62LY",
        "SPEC": "F5IV"
    },
    {
        "NAME": "4The CrB",
        "RA": "15H32M055.78S",
        "DEC": "+31D21M032.88S",
        "APPMAG": 4.14,
        "DIST": "375.32LY",
        "SPEC": "B6Vnn"
    },
    {
        "NAME": "Eta Cru",
        "RA": "12H06M052.87S",
        "DEC": "-64D36M049.43S",
        "APPMAG": 4.14,
        "DIST": "64.43LY",
        "SPEC": "F2III"
    },
    {
        "NAME": "13Eps CrB",
        "RA": "15H57M035.26S",
        "DEC": "+26D52M040.37S",
        "APPMAG": 4.14,
        "DIST": "221.42LY",
        "SPEC": "K3III"
    },
    {
        "NAME": "Merope",
        "RA": "03H46M019.57S",
        "DEC": "+23D56M054.09S",
        "APPMAG": 4.14,
        "DIST": "380.14LY",
        "SPEC": "B6IV"
    },
    {
        "NAME": "5    Tau",
        "RA": "03H30M052.38S",
        "DEC": "+12D56M012.04S",
        "APPMAG": 4.14,
        "DIST": "342.24LY",
        "SPEC": "K0II-III..."
    },
    {
        "NAME": "4Del Hya",
        "RA": "08H37M039.37S",
        "DEC": "+05D42M013.62S",
        "APPMAG": 4.14,
        "DIST": "160.35LY",
        "SPEC": "A1Vnn"
    },
    {
        "NAME": "1    Lac",
        "RA": "22H15M058.18S",
        "DEC": "+37D44M055.45S",
        "APPMAG": 4.14,
        "DIST": "621.25LY",
        "SPEC": "K3III"
    },
    {
        "NAME": "19Kap And",
        "RA": "23H40M024.49S",
        "DEC": "+44D20M002.16S",
        "APPMAG": 4.15,
        "DIST": "168.38LY",
        "SPEC": "B9IVn"
    },
    {
        "NAME": "75Rho Her",
        "RA": "17H23M040.95S",
        "DEC": "+37D08M045.41S",
        "APPMAG": 4.15,
        "DIST": "393.43LY",
        "SPEC": "B9.5III"
    },
    {
        "NAME": "22Del Mon",
        "RA": "07H11M051.86S",
        "DEC": "-00D29M033.95S",
        "APPMAG": 4.15,
        "DIST": "384.17LY",
        "SPEC": "A2V"
    },
    {
        "NAME": "44    Oph",
        "RA": "17H26M022.21S",
        "DEC": "-24D10M031.11S",
        "APPMAG": 4.16,
        "DIST": "83.16LY",
        "SPEC": "A3IV:m"
    },
    {
        "NAME": "1    Gem",
        "RA": "06H04M007.22S",
        "DEC": "+23D15M048.03S",
        "APPMAG": 4.16,
        "DIST": "155.09LY",
        "SPEC": "G7III"
    },
    {
        "NAME": "62Rho Gem",
        "RA": "07H29M006.70S",
        "DEC": "+31D47M004.38S",
        "APPMAG": 4.16,
        "DIST": "58.86LY",
        "SPEC": "F0V..."
    },
    {
        "NAME": "HIP 17874.0",
        "RA": "03H49M027.25S",
        "DEC": "-36D12M000.90S",
        "APPMAG": 4.17,
        "DIST": "209.88LY",
        "SPEC": "G8III"
    },
    {
        "NAME": "Ancha",
        "RA": "22H16M050.03S",
        "DEC": "-07D46M059.84S",
        "APPMAG": 4.17,
        "DIST": "187.45LY",
        "SPEC": "G8III-IV"
    },
    {
        "NAME": "15Kap Cas",
        "RA": "00H32M059.99S",
        "DEC": "+62D55M054.42S",
        "APPMAG": 4.17,
        "DIST": "326156.38LY",
        "SPEC": "B1Ia"
    },
    {
        "NAME": "HIP 81304.0",
        "RA": "16H36M022.47S",
        "DEC": "-35D15M019.17S",
        "APPMAG": 4.18,
        "DIST": "342.60LY",
        "SPEC": "K5III"
    },
    {
        "NAME": "Kang",
        "RA": "14H12M053.74S",
        "DEC": "-10D16M025.33S",
        "APPMAG": 4.18,
        "DIST": "254.81LY",
        "SPEC": "K3III"
    },
    {
        "NAME": "Xuange",
        "RA": "14H16M023.07S",
        "DEC": "+46D05M017.90S",
        "APPMAG": 4.18,
        "DIST": "99.02LY",
        "SPEC": "A0sh"
    },
    {
        "NAME": "23Eps Cep",
        "RA": "22H15M001.96S",
        "DEC": "+57D02M036.91S",
        "APPMAG": 4.18,
        "DIST": "85.45LY",
        "SPEC": "F0IV"
    },
    {
        "NAME": "18Eps PsA",
        "RA": "22H40M039.34S",
        "DEC": "-27D02M037.02S",
        "APPMAG": 4.18,
        "DIST": "486.80LY",
        "SPEC": "B8V"
    },
    {
        "NAME": "2    Cen",
        "RA": "13H49M026.73S",
        "DEC": "-34D27M002.79S",
        "APPMAG": 4.19,
        "DIST": "183.03LY",
        "SPEC": "M5III"
    },
    {
        "NAME": "110    Her",
        "RA": "18H45M039.73S",
        "DEC": "+20D32M046.71S",
        "APPMAG": 4.19,
        "DIST": "62.65LY",
        "SPEC": "F6V"
    },
    {
        "NAME": "32    Ori",
        "RA": "05H30M047.05S",
        "DEC": "+05D56M053.30S",
        "APPMAG": 4.2,
        "DIST": "302.84LY",
        "SPEC": "B5V"
    },
    {
        "NAME": "23Del PsA",
        "RA": "22H55M056.90S",
        "DEC": "-32D32M022.66S",
        "APPMAG": 4.2,
        "DIST": "154.14LY",
        "SPEC": "G8III"
    },
    {
        "NAME": "35Sig Her",
        "RA": "16H34M006.18S",
        "DEC": "+42D26M013.35S",
        "APPMAG": 4.2,
        "DIST": "314.82LY",
        "SPEC": "B9Vvar"
    },
    {
        "NAME": "46Xi  Peg",
        "RA": "22H46M041.58S",
        "DEC": "+12D10M022.40S",
        "APPMAG": 4.2,
        "DIST": "53.15LY",
        "SPEC": "F7V"
    },
    {
        "NAME": "11    Pup",
        "RA": "07H56M051.54S",
        "DEC": "-22D52M048.43S",
        "APPMAG": 4.2,
        "DIST": "521.85LY",
        "SPEC": "F7/F8II"
    },
    {
        "NAME": "31Bet LMi",
        "RA": "10H27M053.02S",
        "DEC": "+36D42M025.96S",
        "APPMAG": 4.2,
        "DIST": "153.92LY",
        "SPEC": "G8III-IV"
    },
    {
        "NAME": "HIP 16228.0",
        "RA": "03H29M004.14S",
        "DEC": "+59D56M025.19S",
        "APPMAG": 4.21,
        "DIST": "1941.41LY",
        "SPEC": "B9Ia"
    },
    {
        "NAME": "Gam Pav",
        "RA": "21H26M026.54S",
        "DEC": "-65D21M058.31S",
        "APPMAG": 4.21,
        "DIST": "30.21LY",
        "SPEC": "F6V"
    },
    {
        "NAME": "22Eps UMi",
        "RA": "16H45M058.17S",
        "DEC": "+82D02M014.14S",
        "APPMAG": 4.21,
        "DIST": "303.97LY",
        "SPEC": "G5IIIvar"
    },
    {
        "NAME": "2The Cep",
        "RA": "20H29M034.85S",
        "DEC": "+62D59M038.78S",
        "APPMAG": 4.21,
        "DIST": "136.47LY",
        "SPEC": "A7III"
    },
    {
        "NAME": "65Kap1Tau",
        "RA": "04H25M022.16S",
        "DEC": "+22D17M037.95S",
        "APPMAG": 4.21,
        "DIST": "153.92LY",
        "SPEC": "A7IV-V"
    },
    {
        "NAME": "43Phi Dra",
        "RA": "18H20M045.44S",
        "DEC": "+71D20M016.13S",
        "APPMAG": 4.22,
        "DIST": "302.84LY",
        "SPEC": "A0p (Si)"
    },
    {
        "NAME": "27Tau6Eri",
        "RA": "03H46M050.89S",
        "DEC": "-23D14M059.00S",
        "APPMAG": 4.22,
        "DIST": "57.49LY",
        "SPEC": "F3/F5V"
    },
    {
        "NAME": "HIP 38518.0",
        "RA": "07H53M018.16S",
        "DEC": "-48D06M010.56S",
        "APPMAG": 4.22,
        "DIST": "1655.62LY",
        "SPEC": "B0.5Ib"
    },
    {
        "NAME": "90Phi Aqr",
        "RA": "23H14M019.36S",
        "DEC": "-06D02M056.41S",
        "APPMAG": 4.22,
        "DIST": "202.08LY",
        "SPEC": "M2III"
    },
    {
        "NAME": "Bet Sct",
        "RA": "18H47M010.47S",
        "DEC": "-04D44M052.32S",
        "APPMAG": 4.22,
        "DIST": "916.17LY",
        "SPEC": "G5II..."
    },
    {
        "NAME": "7Chi Oph",
        "RA": "16H27M001.44S",
        "DEC": "-18D27M022.50S",
        "APPMAG": 4.22,
        "DIST": "525.21LY",
        "SPEC": "B2Vne"
    },
    {
        "NAME": "12Del2Lyr",
        "RA": "18H54M030.28S",
        "DEC": "+36D53M055.01S",
        "APPMAG": 4.22,
        "DIST": "736.24LY",
        "SPEC": "M4IIvar"
    },
    {
        "NAME": "67Sig Cyg",
        "RA": "21H17M024.95S",
        "DEC": "+39D23M040.85S",
        "APPMAG": 4.22,
        "DIST": "2886.34LY",
        "SPEC": "B9Iab"
    },
    {
        "NAME": "Lam Pav",
        "RA": "18H52M013.04S",
        "DEC": "-62D11M015.33S",
        "APPMAG": 4.22,
        "DIST": "1430.51LY",
        "SPEC": "B2II-III"
    },
    {
        "NAME": "52    Cyg",
        "RA": "20H45M039.75S",
        "DEC": "+30D43M010.97S",
        "APPMAG": 4.22,
        "DIST": "201.08LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "The Lup",
        "RA": "16H06M035.55S",
        "DEC": "-36D48M008.24S",
        "APPMAG": 4.22,
        "DIST": "414.43LY",
        "SPEC": "B2.5Vn"
    },
    {
        "NAME": "16    Per",
        "RA": "02H50M035.03S",
        "DEC": "+38D19M007.12S",
        "APPMAG": 4.22,
        "DIST": "120.75LY",
        "SPEC": "F2III"
    },
    {
        "NAME": "93Tau Vir",
        "RA": "14H01M038.79S",
        "DEC": "+01D32M040.32S",
        "APPMAG": 4.23,
        "DIST": "224.94LY",
        "SPEC": "A3V"
    },
    {
        "NAME": "11Phi Her",
        "RA": "16H08M046.18S",
        "DEC": "+44D56M005.66S",
        "APPMAG": 4.23,
        "DIST": "203.98LY",
        "SPEC": "B9MNp..."
    },
    {
        "NAME": "Zet Tuc",
        "RA": "00H20M002.91S",
        "DEC": "-64D52M029.25S",
        "APPMAG": 4.23,
        "DIST": "28.01LY",
        "SPEC": "F9V"
    },
    {
        "NAME": "1    Cen",
        "RA": "13H45M041.30S",
        "DEC": "-33D02M037.40S",
        "APPMAG": 4.23,
        "DIST": "63.28LY",
        "SPEC": "F3V"
    },
    {
        "NAME": "Bet Aps",
        "RA": "16H43M005.25S",
        "DEC": "-77D31M002.77S",
        "APPMAG": 4.23,
        "DIST": "156.96LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "75Sig Gem",
        "RA": "07H43M018.72S",
        "DEC": "+28D53M000.64S",
        "APPMAG": 4.23,
        "DIST": "125.06LY",
        "SPEC": "K1III SB"
    },
    {
        "NAME": "Mu  Cep",
        "RA": "21H43M030.46S",
        "DEC": "+58D46M048.17S",
        "APPMAG": 4.23,
        "DIST": "326156.38LY",
        "SPEC": "M2Ia"
    },
    {
        "NAME": "43Bet Com",
        "RA": "13H11M052.45S",
        "DEC": "+27D52M041.46S",
        "APPMAG": 4.23,
        "DIST": "29.78LY",
        "SPEC": "G0V"
    },
    {
        "NAME": "81Pi 2Cyg",
        "RA": "21H46M047.61S",
        "DEC": "+49D18M034.45S",
        "APPMAG": 4.23,
        "DIST": "1105.62LY",
        "SPEC": "B3III"
    },
    {
        "NAME": "Gam CrA",
        "RA": "19H06M025.10S",
        "DEC": "-37D03M048.37S",
        "APPMAG": 4.23,
        "DIST": "56.44LY",
        "SPEC": "F7IV-V"
    },
    {
        "NAME": "Kap Eri",
        "RA": "02H26M059.12S",
        "DEC": "-47D42M013.82S",
        "APPMAG": 4.24,
        "DIST": "508.03LY",
        "SPEC": "B5IV"
    },
    {
        "NAME": "Bet Cha",
        "RA": "12H18M020.92S",
        "DEC": "-79D18M044.06S",
        "APPMAG": 4.24,
        "DIST": "298.40LY",
        "SPEC": "B5Vn"
    },
    {
        "NAME": "56Omi Ser",
        "RA": "17H41M024.87S",
        "DEC": "-12D52M031.11S",
        "APPMAG": 4.24,
        "DIST": "173.21LY",
        "SPEC": "A2Va"
    },
    {
        "NAME": "91Psi1Aqr",
        "RA": "23H15M053.49S",
        "DEC": "-09D05M015.85S",
        "APPMAG": 4.24,
        "DIST": "149.82LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "HIP 5372.0",
        "RA": "01H08M044.21S",
        "DEC": "+86D15M025.52S",
        "APPMAG": 4.24,
        "DIST": "280.20LY",
        "SPEC": "K2II-III"
    },
    {
        "NAME": "HIP 80911.0",
        "RA": "16H31M022.93S",
        "DEC": "-34D42M015.72S",
        "APPMAG": 4.24,
        "DIST": "554.69LY",
        "SPEC": "B2III-IV"
    },
    {
        "NAME": "89Pi  Cet",
        "RA": "02H44M007.35S",
        "DEC": "-13D51M031.31S",
        "APPMAG": 4.24,
        "DIST": "392.96LY",
        "SPEC": "B7IV"
    },
    {
        "NAME": "Chara",
        "RA": "12H33M044.68S",
        "DEC": "+41D21M026.93S",
        "APPMAG": 4.24,
        "DIST": "27.53LY",
        "SPEC": "G0V"
    },
    {
        "NAME": "69Lam Eri",
        "RA": "05H09M008.78S",
        "DEC": "-08D45M014.69S",
        "APPMAG": 4.25,
        "DIST": "811.33LY",
        "SPEC": "B2IVn"
    },
    {
        "NAME": "88    Tau",
        "RA": "04H35M039.26S",
        "DEC": "+10D09M038.84S",
        "APPMAG": 4.25,
        "DIST": "156.21LY",
        "SPEC": "A5m"
    },
    {
        "NAME": "10Nu  Cep",
        "RA": "21H45M026.93S",
        "DEC": "+61D07M014.90S",
        "APPMAG": 4.25,
        "DIST": "326156.38LY",
        "SPEC": "A2Iavar"
    },
    {
        "NAME": "Kap Tuc",
        "RA": "01H15M045.73S",
        "DEC": "-68D52M033.34S",
        "APPMAG": 4.25,
        "DIST": "68.35LY",
        "SPEC": "F6IV"
    },
    {
        "NAME": "58    Per",
        "RA": "04H36M041.43S",
        "DEC": "+41D15M053.31S",
        "APPMAG": 4.25,
        "DIST": "797.45LY",
        "SPEC": "G8II comp"
    },
    {
        "NAME": "Gl 488.1",
        "RA": "12H53M026.19S",
        "DEC": "-40D10M043.94S",
        "APPMAG": 4.25,
        "DIST": "148.59LY",
        "SPEC": "A4IV"
    },
    {
        "NAME": "Alsciaukat",
        "RA": "08H22M050.12S",
        "DEC": "+43D11M017.27S",
        "APPMAG": 4.25,
        "DIST": "382.36LY",
        "SPEC": "K5III"
    },
    {
        "NAME": "47Lam Per",
        "RA": "04H06M035.05S",
        "DEC": "+50D21M004.54S",
        "APPMAG": 4.25,
        "DIST": "421.94LY",
        "SPEC": "A0IVn"
    },
    {
        "NAME": "5    UMi",
        "RA": "14H27M031.53S",
        "DEC": "+75D41M045.57S",
        "APPMAG": 4.25,
        "DIST": "358.81LY",
        "SPEC": "K4III"
    },
    {
        "NAME": "HIP 86170.0",
        "RA": "17H36M032.84S",
        "DEC": "-38D38M007.11S",
        "APPMAG": 4.26,
        "DIST": "165.81LY",
        "SPEC": "G8/K0III/IV"
    },
    {
        "NAME": "82 G. Eri",
        "RA": "03H19M055.00S",
        "DEC": "-43D04M011.22S",
        "APPMAG": 4.26,
        "DIST": "19.71LY",
        "SPEC": "G8V"
    },
    {
        "NAME": "Acubens",
        "RA": "08H58M029.22S",
        "DEC": "+11D51M027.72S",
        "APPMAG": 4.26,
        "DIST": "188.31LY",
        "SPEC": "A5m"
    },
    {
        "NAME": "95    Her",
        "RA": "18H01M030.41S",
        "DEC": "+21D35M044.82S",
        "APPMAG": 4.26,
        "DIST": "417.08LY",
        "SPEC": "G5"
    },
    {
        "NAME": "Gam Dor",
        "RA": "04H16M001.55S",
        "DEC": "-51D29M011.93S",
        "APPMAG": 4.26,
        "DIST": "66.74LY",
        "SPEC": "F4III"
    },
    {
        "NAME": "Kurhah",
        "RA": "22H03M047.29S",
        "DEC": "+64D37M040.70S",
        "APPMAG": 4.26,
        "DIST": "96.52LY",
        "SPEC": "Am"
    },
    {
        "NAME": "Torcular",
        "RA": "01H45M023.63S",
        "DEC": "+09D09M027.85S",
        "APPMAG": 4.26,
        "DIST": "279.48LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "19Tau5Eri",
        "RA": "03H33M047.28S",
        "DEC": "-21D37M058.38S",
        "APPMAG": 4.26,
        "DIST": "293.31LY",
        "SPEC": "B9V"
    },
    {
        "NAME": "42Phi And",
        "RA": "01H09M030.12S",
        "DEC": "+47D14M030.45S",
        "APPMAG": 4.26,
        "DIST": "716.83LY",
        "SPEC": "B7III"
    },
    {
        "NAME": "9Alp Cam",
        "RA": "04H54M003.01S",
        "DEC": "+66D20M033.64S",
        "APPMAG": 4.26,
        "DIST": "326156.38LY",
        "SPEC": "O9.5Ia SB:"
    },
    {
        "NAME": "49Mu  Tau",
        "RA": "04H15M032.06S",
        "DEC": "+08D53M032.49S",
        "APPMAG": 4.27,
        "DIST": "455.53LY",
        "SPEC": "B3IV"
    },
    {
        "NAME": "87Mu  Cet",
        "RA": "02H44M056.54S",
        "DEC": "+10D06M050.93S",
        "APPMAG": 4.27,
        "DIST": "84.06LY",
        "SPEC": "F1III-IV"
    },
    {
        "NAME": "12Gam2Del",
        "RA": "20H46M039.50S",
        "DEC": "+16D07M027.47S",
        "APPMAG": 4.27,
        "DIST": "126.32LY",
        "SPEC": "K1IV"
    },
    {
        "NAME": "94Tau Tau",
        "RA": "04H42M014.70S",
        "DEC": "+22D57M024.93S",
        "APPMAG": 4.27,
        "DIST": "398.24LY",
        "SPEC": "B3V"
    },
    {
        "NAME": "Arkab Posterior",
        "RA": "19H23M013.11S",
        "DEC": "-44D47M059.20S",
        "APPMAG": 4.27,
        "DIST": "134.17LY",
        "SPEC": "F2III"
    },
    {
        "NAME": "71Eps Psc",
        "RA": "01H02M056.61S",
        "DEC": "+07D53M024.49S",
        "APPMAG": 4.27,
        "DIST": "181.80LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "Xi 2Cen",
        "RA": "13H06M054.65S",
        "DEC": "-49D54M022.49S",
        "APPMAG": 4.27,
        "DIST": "467.27LY",
        "SPEC": "B1.5V"
    },
    {
        "NAME": "10The Psc",
        "RA": "23H27M058.10S",
        "DEC": "+06D22M044.37S",
        "APPMAG": 4.27,
        "DIST": "148.52LY",
        "SPEC": "K1III"
    },
    {
        "NAME": "Mu  Lup",
        "RA": "15H18M032.03S",
        "DEC": "-47D52M030.98S",
        "APPMAG": 4.27,
        "DIST": "335.55LY",
        "SPEC": "B8V"
    },
    {
        "NAME": "90    Tau",
        "RA": "04H38M009.46S",
        "DEC": "+12D30M039.02S",
        "APPMAG": 4.27,
        "DIST": "153.56LY",
        "SPEC": "A6V"
    },
    {
        "NAME": "69Ups Tau",
        "RA": "04H26M018.46S",
        "DEC": "+22D48M048.90S",
        "APPMAG": 4.28,
        "DIST": "153.77LY",
        "SPEC": "A8Vn"
    },
    {
        "NAME": "33    Cyg",
        "RA": "20H13M023.84S",
        "DEC": "+56D34M003.80S",
        "APPMAG": 4.28,
        "DIST": "159.26LY",
        "SPEC": "A3IV-Vn"
    },
    {
        "NAME": "The Gru",
        "RA": "23H06M052.74S",
        "DEC": "-43D31M013.29S",
        "APPMAG": 4.28,
        "DIST": "131.89LY",
        "SPEC": "F5me..."
    },
    {
        "NAME": "32Iot Cap",
        "RA": "21H22M014.79S",
        "DEC": "-16D50M004.35S",
        "APPMAG": 4.28,
        "DIST": "196.72LY",
        "SPEC": "G8III"
    },
    {
        "NAME": "HIP 47193.0",
        "RA": "09H37M005.34S",
        "DEC": "+81D19M034.98S",
        "APPMAG": 4.28,
        "DIST": "994.38LY",
        "SPEC": "K3III"
    },
    {
        "NAME": "Alp Ant",
        "RA": "10H27M009.11S",
        "DEC": "-31D04M004.00S",
        "APPMAG": 4.28,
        "DIST": "366.06LY",
        "SPEC": "K4III"
    },
    {
        "NAME": "29Pi 2Peg",
        "RA": "22H09M059.25S",
        "DEC": "+33D10M041.61S",
        "APPMAG": 4.28,
        "DIST": "263.03LY",
        "SPEC": "F5III"
    },
    {
        "NAME": "45    Oph",
        "RA": "17H27M021.27S",
        "DEC": "-29D52M001.32S",
        "APPMAG": 4.28,
        "DIST": "111.58LY",
        "SPEC": "F3III"
    },
    {
        "NAME": "10    Tau",
        "RA": "03H36M052.38S",
        "DEC": "+00D24M005.98S",
        "APPMAG": 4.29,
        "DIST": "45.54LY",
        "SPEC": "F9V"
    },
    {
        "NAME": "33Iot Aqr",
        "RA": "22H06M026.23S",
        "DEC": "-13D52M010.84S",
        "APPMAG": 4.29,
        "DIST": "175.16LY",
        "SPEC": "B8V"
    },
    {
        "NAME": "16Zet UMi",
        "RA": "15H44M003.48S",
        "DEC": "+77D47M040.17S",
        "APPMAG": 4.29,
        "DIST": "368.96LY",
        "SPEC": "A3Vn"
    },
    {
        "NAME": "17Iot And",
        "RA": "23H38M008.20S",
        "DEC": "+43D16M005.06S",
        "APPMAG": 4.29,
        "DIST": "499.47LY",
        "SPEC": "B8V"
    },
    {
        "NAME": "HIP 52154.0",
        "RA": "10H39M018.40S",
        "DEC": "-55D36M011.76S",
        "APPMAG": 4.29,
        "DIST": "840.61LY",
        "SPEC": "G2II"
    },
    {
        "NAME": "17Bet PsA",
        "RA": "22H31M030.32S",
        "DEC": "-32D20M045.86S",
        "APPMAG": 4.29,
        "DIST": "142.80LY",
        "SPEC": "A1V"
    },
    {
        "NAME": "Bet Hya",
        "RA": "11H52M054.53S",
        "DEC": "-33D54M029.25S",
        "APPMAG": 4.29,
        "DIST": "309.74LY",
        "SPEC": "Ap Si"
    },
    {
        "NAME": "6Lam Lep",
        "RA": "05H19M034.53S",
        "DEC": "-13D10M036.44S",
        "APPMAG": 4.29,
        "DIST": "851.58LY",
        "SPEC": "B0.5IV"
    },
    {
        "NAME": "8Phi Oph",
        "RA": "16H31M008.37S",
        "DEC": "-16D36M045.84S",
        "APPMAG": 4.29,
        "DIST": "243.58LY",
        "SPEC": "G8/K0III"
    },
    {
        "NAME": "54    Leo",
        "RA": "10H55M036.80S",
        "DEC": "+24D44M058.98S",
        "APPMAG": 4.3,
        "DIST": "286.86LY",
        "SPEC": "A1"
    },
    {
        "NAME": "68Del3Tau",
        "RA": "04H25M029.38S",
        "DEC": "+17D55M040.48S",
        "APPMAG": 4.3,
        "DIST": "148.52LY",
        "SPEC": "A2IV"
    },
    {
        "NAME": "Alp Scl",
        "RA": "00H58M036.36S",
        "DEC": "-29D21M026.82S",
        "APPMAG": 4.3,
        "DIST": "776.56LY",
        "SPEC": "B7IIIp"
    },
    {
        "NAME": "5Alp1Cap",
        "RA": "20H17M038.87S",
        "DEC": "-12D30M029.56S",
        "APPMAG": 4.3,
        "DIST": "569.21LY",
        "SPEC": "G3Ib"
    },
    {
        "NAME": "HIP 70069.0",
        "RA": "14H20M019.55S",
        "DEC": "-56D23M011.39S",
        "APPMAG": 4.3,
        "DIST": "1226.15LY",
        "SPEC": "B6Ib"
    },
    {
        "NAME": "7Eta Hya",
        "RA": "08H43M013.48S",
        "DEC": "+03D23M055.18S",
        "APPMAG": 4.3,
        "DIST": "586.61LY",
        "SPEC": "B3V..."
    },
    {
        "NAME": "Taygeta",
        "RA": "03H45M012.49S",
        "DEC": "+24D28M002.20S",
        "APPMAG": 4.3,
        "DIST": "409.23LY",
        "SPEC": "B6V"
    },
    {
        "NAME": "8Eta Crv",
        "RA": "12H32M004.24S",
        "DEC": "-16D11M045.63S",
        "APPMAG": 4.3,
        "DIST": "59.63LY",
        "SPEC": "F2V"
    },
    {
        "NAME": "91Ups Leo",
        "RA": "11H36M056.93S",
        "DEC": "-00D49M025.50S",
        "APPMAG": 4.3,
        "DIST": "181.50LY",
        "SPEC": "G9III"
    },
    {
        "NAME": "35Pi  Aur",
        "RA": "05H59M056.10S",
        "DEC": "+45D56M012.25S",
        "APPMAG": 4.3,
        "DIST": "751.51LY",
        "SPEC": "M3IIvar"
    },
    {
        "NAME": "HIP 17797.0",
        "RA": "03H48M035.87S",
        "DEC": "-37D37M012.56S",
        "APPMAG": 4.3,
        "DIST": "165.48LY",
        "SPEC": "A+..."
    },
    {
        "NAME": "73Xi 2Cet",
        "RA": "02H28M009.54S",
        "DEC": "+08D27M036.19S",
        "APPMAG": 4.3,
        "DIST": "193.11LY",
        "SPEC": "B9III"
    },
    {
        "NAME": "HIP 57669.0",
        "RA": "11H49M041.08S",
        "DEC": "-63D47M018.52S",
        "APPMAG": 4.3,
        "DIST": "595.18LY",
        "SPEC": "B3V"
    },
    {
        "NAME": "HIP 42568.0",
        "RA": "08H40M037.03S",
        "DEC": "-59D45M039.61S",
        "APPMAG": 4.31,
        "DIST": "1443.17LY",
        "SPEC": "B1.5III"
    },
    {
        "NAME": "Alkalurops",
        "RA": "15H24M029.45S",
        "DEC": "+37D22M037.80S",
        "APPMAG": 4.31,
        "DIST": "113.13LY",
        "SPEC": "F0V"
    },
    {
        "NAME": "71    Aql",
        "RA": "20H38M020.28S",
        "DEC": "-01D06M018.44S",
        "APPMAG": 4.31,
        "DIST": "337.29LY",
        "SPEC": "G8III SB"
    },
    {
        "NAME": "Del Oct",
        "RA": "14H26M055.68S",
        "DEC": "-83D40M004.38S",
        "APPMAG": 4.31,
        "DIST": "298.95LY",
        "SPEC": "K2III"
    },
    {
        "NAME": "10Ome2Sco",
        "RA": "16H07M024.33S",
        "DEC": "-20D52M007.55S",
        "APPMAG": 4.31,
        "DIST": "290.69LY",
        "SPEC": "G6/G8III"
    },
    {
        "NAME": "54    Eri",
        "RA": "04H40M026.51S",
        "DEC": "-19D40M017.37S",
        "APPMAG": 4.32,
        "DIST": "368.54LY",
        "SPEC": "M3/M4III"
    },
    {
        "NAME": "Alterf",
        "RA": "09H31M043.23S",
        "DEC": "+22D58M004.70S",
        "APPMAG": 4.32,
        "DIST": "329.12LY",
        "SPEC": "K5IIIvar"
    },
    {
        "NAME": "37Psi Per",
        "RA": "03H36M029.37S",
        "DEC": "+48D11M033.48S",
        "APPMAG": 4.32,
        "DIST": "583.46LY",
        "SPEC": "B5Ve"
    },
    {
        "NAME": "119    Tau",
        "RA": "05H32M012.75S",
        "DEC": "+18D35M039.24S",
        "APPMAG": 4.32,
        "DIST": "1792.07LY",
        "SPEC": "M2Ib"
    },
    {
        "NAME": "12    Hya",
        "RA": "08H46M022.54S",
        "DEC": "-13D32M051.79S",
        "APPMAG": 4.32,
        "DIST": "245.05LY",
        "SPEC": "G8III"
    },
    {
        "NAME": "3    Cen",
        "RA": "13H51M049.60S",
        "DEC": "-32D59M038.72S",
        "APPMAG": 4.32,
        "DIST": "343.68LY",
        "SPEC": "B5"
    },
    {
        "NAME": "Omi Lup",
        "RA": "14H51M038.31S",
        "DEC": "-43D34M031.29S",
        "APPMAG": 4.32,
        "DIST": "404.16LY",
        "SPEC": "B5IV"
    },
    {
        "NAME": "The1Cru",
        "RA": "12H03M001.61S",
        "DEC": "-63D18M046.55S",
        "APPMAG": 4.32,
        "DIST": "234.98LY",
        "SPEC": "Am"
    },
    {
        "NAME": "53Nu  Ser",
        "RA": "17H20M049.66S",
        "DEC": "-12D50M048.75S",
        "APPMAG": 4.32,
        "DIST": "203.21LY",
        "SPEC": "A0/A1V"
    },
    {
        "NAME": "44Kap Aur",
        "RA": "06H15M022.69S",
        "DEC": "+29D29M053.07S",
        "APPMAG": 4.32,
        "DIST": "176.97LY",
        "SPEC": "G8IIIvar"
    },
    {
        "NAME": "Diadem",
        "RA": "13H09M059.29S",
        "DEC": "+17D31M045.95S",
        "APPMAG": 4.32,
        "DIST": "58.14LY",
        "SPEC": "F5V"
    },
    {
        "NAME": "Guniibuu",
        "RA": "17H15M021.01S",
        "DEC": "-26D36M010.18S",
        "APPMAG": 4.33,
        "DIST": "19.35LY",
        "SPEC": "K2:III:"
    },
    {
        "NAME": "Tau2Lup",
        "RA": "14H26M010.81S",
        "DEC": "-45D22M045.39S",
        "APPMAG": 4.33,
        "DIST": "319.14LY",
        "SPEC": "A7:+..."
    },
    {
        "NAME": "Alula Australis",
        "RA": "11H18M011.22S",
        "DEC": "+31D31M043.62S",
        "APPMAG": 4.33,
        "DIST": "33.97LY",
        "SPEC": "G0 Ve"
    },
    {
        "NAME": "1Kap Lyr",
        "RA": "18H19M051.71S",
        "DEC": "+36D03M052.37S",
        "APPMAG": 4.33,
        "DIST": "251.66LY",
        "SPEC": "K2IIIvar"
    },
    {
        "NAME": "Pi  Pav",
        "RA": "18H08M034.80S",
        "DEC": "-63D40M006.79S",
        "APPMAG": 4.33,
        "DIST": "129.99LY",
        "SPEC": "Am"
    },
    {
        "NAME": "HIP 62867.0",
        "RA": "12H53M006.93S",
        "DEC": "-48D56M035.93S",
        "APPMAG": 4.33,
        "DIST": "294.36LY",
        "SPEC": "K3/K4III"
    },
    {
        "NAME": "4Gam CMi",
        "RA": "07H28M009.79S",
        "DEC": "+08D55M031.91S",
        "APPMAG": 4.33,
        "DIST": "318.20LY",
        "SPEC": "K3III SB"
    },
    {
        "NAME": "Del Dor",
        "RA": "05H44M046.40S",
        "DEC": "-65D44M007.89S",
        "APPMAG": 4.34,
        "DIST": "149.61LY",
        "SPEC": "A7V"
    },
    {
        "NAME": "9    Peg",
        "RA": "21H44M030.70S",
        "DEC": "+17D21M000.06S",
        "APPMAG": 4.34,
        "DIST": "926.58LY",
        "SPEC": "G5Ib"
    },
    {
        "NAME": "49Sig Oph",
        "RA": "17H26M030.88S",
        "DEC": "+04D08M025.30S",
        "APPMAG": 4.34,
        "DIST": "900.98LY",
        "SPEC": "K3IIvar"
    },
    {
        "NAME": "Ups2Cen",
        "RA": "14H01M043.49S",
        "DEC": "-45D36M012.32S",
        "APPMAG": 4.34,
        "DIST": "1269.09LY",
        "SPEC": "F6II"
    },
    {
        "NAME": "Ome Lup",
        "RA": "15H38M003.24S",
        "DEC": "-42D34M002.45S",
        "APPMAG": 4.34,
        "DIST": "218.60LY",
        "SPEC": "K4.5III"
    },
    {
        "NAME": "HIP 47175.0",
        "RA": "09H36M049.58S",
        "DEC": "-49D21M018.09S",
        "APPMAG": 4.34,
        "DIST": "105.42LY",
        "SPEC": "A5V"
    },
    {
        "NAME": "111    Her",
        "RA": "18H47M001.27S",
        "DEC": "+18D10M053.47S",
        "APPMAG": 4.34,
        "DIST": "94.24LY",
        "SPEC": "A5III"
    },
    {
        "NAME": "4Xi 1CMa",
        "RA": "06H31M051.37S",
        "DEC": "-23D25M006.32S",
        "APPMAG": 4.34,
        "DIST": "1382.02LY",
        "SPEC": "B1III"
    },
    {
        "NAME": "The Cha",
        "RA": "08H20M038.81S",
        "DEC": "-77D29M004.12S",
        "APPMAG": 4.34,
        "DIST": "155.31LY",
        "SPEC": "K0III-IV"
    },
    {
        "NAME": "33The Cas",
        "RA": "01H11M006.06S",
        "DEC": "+55D08M059.64S",
        "APPMAG": 4.34,
        "DIST": "133.56LY",
        "SPEC": "A7Vvar"
    },
    {
        "NAME": "5    Lac",
        "RA": "22H29M031.82S",
        "DEC": "+47D42M024.79S",
        "APPMAG": 4.34,
        "DIST": "1647.25LY",
        "SPEC": "M0II"
    },
    {
        "NAME": "6Zet1Lyr",
        "RA": "18H44M046.35S",
        "DEC": "+37D36M018.41S",
        "APPMAG": 4.34,
        "DIST": "156.13LY",
        "SPEC": "Am"
    },
    {
        "NAME": "HIP 45496.0",
        "RA": "09H16M012.09S",
        "DEC": "-57D32M029.30S",
        "APPMAG": 4.34,
        "DIST": "488.26LY",
        "SPEC": "M1III"
    },
    {
        "NAME": "29Pi  And",
        "RA": "00H36M052.85S",
        "DEC": "+33D43M009.64S",
        "APPMAG": 4.34,
        "DIST": "598.45LY",
        "SPEC": "B5V"
    },
    {
        "NAME": "30Eps And",
        "RA": "00H38M033.37S",
        "DEC": "+29D18M042.30S",
        "APPMAG": 4.34,
        "DIST": "163.82LY",
        "SPEC": "G5III..."
    },
    {
        "NAME": "2Pi 2Ori",
        "RA": "04H50M036.72S",
        "DEC": "+08D54M000.63S",
        "APPMAG": 4.35,
        "DIST": "224.47LY",
        "SPEC": "A1Vn"
    },
    {
        "NAME": "Xi  Pav",
        "RA": "18H23M013.62S",
        "DEC": "-61D29M038.04S",
        "APPMAG": 4.35,
        "DIST": "468.62LY",
        "SPEC": "M1III SB"
    },
    {
        "NAME": "Eps Vol",
        "RA": "08H07M055.82S",
        "DEC": "-68D37M001.42S",
        "APPMAG": 4.35,
        "DIST": "562.34LY",
        "SPEC": "B6IV"
    },
    {
        "NAME": "21The Lyr",
        "RA": "19H16M022.09S",
        "DEC": "+38D08M001.43S",
        "APPMAG": 4.35,
        "DIST": "832.03LY",
        "SPEC": "K0II"
    },
    {
        "NAME": "2    Lup",
        "RA": "15H17M049.84S",
        "DEC": "-30D08M055.22S",
        "APPMAG": 4.35,
        "DIST": "325.83LY",
        "SPEC": "K1II/III"
    },
    {
        "NAME": "15    Lyn",
        "RA": "06H57M016.60S",
        "DEC": "+58D25M021.93S",
        "APPMAG": 4.35,
        "DIST": "178.33LY",
        "SPEC": "G5III-IV"
    },
    {
        "NAME": "HIP 31407.0",
        "RA": "06H34M058.58S",
        "DEC": "-52D58M032.19S",
        "APPMAG": 4.35,
        "DIST": "1364.67LY",
        "SPEC": "B9III"
    },
    {
        "NAME": "9Iot PsA",
        "RA": "21H44M056.81S",
        "DEC": "-33D01M032.81S",
        "APPMAG": 4.35,
        "DIST": "204.23LY",
        "SPEC": "B9.5V"
    },
    {
        "NAME": "Botein",
        "RA": "03H11M037.76S",
        "DEC": "+19D43M036.04S",
        "APPMAG": 4.35,
        "DIST": "169.70LY",
        "SPEC": "K2IIIvar"
    },
    {
        "NAME": "15Gam Com",
        "RA": "12H26M056.28S",
        "DEC": "+28D16M006.32S",
        "APPMAG": 4.35,
        "DIST": "167.26LY",
        "SPEC": "K2IIICN+..."
    },
    {
        "NAME": "13Rho Hya",
        "RA": "08H48M025.97S",
        "DEC": "+05D50M016.12S",
        "APPMAG": 4.35,
        "DIST": "354.13LY",
        "SPEC": "A0Vn"
    },
    {
        "NAME": "Yildun",
        "RA": "17H32M012.90S",
        "DEC": "+86D35M011.26S",
        "APPMAG": 4.35,
        "DIST": "172.11LY",
        "SPEC": "A1Vn"
    },
    {
        "NAME": "Eta Phe",
        "RA": "00H43M021.24S",
        "DEC": "-57D27M047.02S",
        "APPMAG": 4.36,
        "DIST": "246.34LY",
        "SPEC": "A0IV"
    },
    {
        "NAME": "20Iot CMa",
        "RA": "06H56M008.22S",
        "DEC": "-17D03M015.27S",
        "APPMAG": 4.36,
        "DIST": "2508.90LY",
        "SPEC": "B3Ib/II"
    },
    {
        "NAME": "4Kap Lep",
        "RA": "05H13M013.88S",
        "DEC": "-12D56M028.65S",
        "APPMAG": 4.36,
        "DIST": "728.03LY",
        "SPEC": "B7V"
    },
    {
        "NAME": "Chi Cen",
        "RA": "14H06M002.77S",
        "DEC": "-41D10M046.68S",
        "APPMAG": 4.36,
        "DIST": "510.42LY",
        "SPEC": "B2V"
    },
    {
        "NAME": "35Sig Per",
        "RA": "03H30M034.48S",
        "DEC": "+47D59M042.78S",
        "APPMAG": 4.36,
        "DIST": "359.60LY",
        "SPEC": "K3III"
    },
    {
        "NAME": "Gam Col",
        "RA": "05H57M032.21S",
        "DEC": "-35D16M059.81S",
        "APPMAG": 4.36,
        "DIST": "869.75LY",
        "SPEC": "B2.5IV"
    },
    {
        "NAME": "61Ome Eri",
        "RA": "04H52M053.67S",
        "DEC": "-05D27M009.70S",
        "APPMAG": 4.36,
        "DIST": "234.98LY",
        "SPEC": "A9IV"
    },
    {
        "NAME": "Bet1Tuc",
        "RA": "00H31M032.61S",
        "DEC": "-62D57M029.58S",
        "APPMAG": 4.36,
        "DIST": "135.05LY",
        "SPEC": "B9V"
    },
    {
        "NAME": "65Xi 1Cet",
        "RA": "02H12M059.99S",
        "DEC": "+08D50M048.18S",
        "APPMAG": 4.36,
        "DIST": "383.26LY",
        "SPEC": "G8II:"
    },
    {
        "NAME": "41Iot Aql",
        "RA": "19H36M043.28S",
        "DEC": "-01D17M011.76S",
        "APPMAG": 4.36,
        "DIST": "391.07LY",
        "SPEC": "B5III"
    },
    {
        "NAME": "29Zet Mon",
        "RA": "08H08M035.65S",
        "DEC": "-02D59M001.63S",
        "APPMAG": 4.36,
        "DIST": "1058.95LY",
        "SPEC": "G2Ib"
    },
    {
        "NAME": "37    Tau",
        "RA": "04H04M041.71S",
        "DEC": "+22D04M054.93S",
        "APPMAG": 4.36,
        "DIST": "187.12LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "HIP 53773.0",
        "RA": "11H00M009.26S",
        "DEC": "-42D13M033.09S",
        "APPMAG": 4.37,
        "DIST": "196.24LY",
        "SPEC": "A3IV"
    },
    {
        "NAME": "30    Psc",
        "RA": "00H01M057.62S",
        "DEC": "-06D00M050.66S",
        "APPMAG": 4.37,
        "DIST": "432.00LY",
        "SPEC": "M3III"
    },
    {
        "NAME": "102    Her",
        "RA": "18H08M045.49S",
        "DEC": "+20D48M052.41S",
        "APPMAG": 4.37,
        "DIST": "916.17LY",
        "SPEC": "B2IV"
    },
    {
        "NAME": "Kap Col",
        "RA": "06H16M033.14S",
        "DEC": "-35D08M025.87S",
        "APPMAG": 4.37,
        "DIST": "182.52LY",
        "SPEC": "G8II"
    },
    {
        "NAME": "The1Sgr",
        "RA": "19H59M044.18S",
        "DEC": "-35D16M034.70S",
        "APPMAG": 4.37,
        "DIST": "518.53LY",
        "SPEC": "B2.5IV"
    },
    {
        "NAME": "30Tau CMa",
        "RA": "07H18M042.49S",
        "DEC": "-24D57M015.75S",
        "APPMAG": 4.37,
        "DIST": "2992.26LY",
        "SPEC": "O9Ib"
    },
    {
        "NAME": "51The Vir",
        "RA": "13H09M056.99S",
        "DEC": "-05D32M020.44S",
        "APPMAG": 4.38,
        "DIST": "315.74LY",
        "SPEC": "A1V"
    },
    {
        "NAME": "99    Aqr",
        "RA": "23H26M002.79S",
        "DEC": "-20D38M031.25S",
        "APPMAG": 4.38,
        "DIST": "283.37LY",
        "SPEC": "K4III"
    },
    {
        "NAME": "1Kap Cep",
        "RA": "20H08M053.32S",
        "DEC": "+77D42M041.11S",
        "APPMAG": 4.38,
        "DIST": "314.82LY",
        "SPEC": "B9III"
    },
    {
        "NAME": "Bet Scl",
        "RA": "23H32M058.24S",
        "DEC": "-37D49M005.76S",
        "APPMAG": 4.38,
        "DIST": "174.04LY",
        "SPEC": "B9.5IVMNpe."
    },
    {
        "NAME": "Psi Phe",
        "RA": "01H53M038.77S",
        "DEC": "-46D18M009.61S",
        "APPMAG": 4.39,
        "DIST": "341.88LY",
        "SPEC": "M4III SB"
    },
    {
        "NAME": "37Phi1Ori",
        "RA": "05H34M049.24S",
        "DEC": "+09D29M022.48S",
        "APPMAG": 4.39,
        "DIST": "1087.19LY",
        "SPEC": "B0IV..."
    },
    {
        "NAME": "The Ind",
        "RA": "21H19M051.95S",
        "DEC": "-53D26M057.94S",
        "APPMAG": 4.39,
        "DIST": "98.78LY",
        "SPEC": "A5V"
    },
    {
        "NAME": "54Chi1Ori",
        "RA": "05H54M022.99S",
        "DEC": "+20D16M034.23S",
        "APPMAG": 4.39,
        "DIST": "28.26LY",
        "SPEC": "G0V"
    },
    {
        "NAME": "110    Vir",
        "RA": "15H02M054.04S",
        "DEC": "+02D05M028.69S",
        "APPMAG": 4.39,
        "DIST": "195.42LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "40Xi  Oph",
        "RA": "17H21M000.36S",
        "DEC": "-21D06M046.56S",
        "APPMAG": 4.39,
        "DIST": "56.60LY",
        "SPEC": "F2/F3V"
    },
    {
        "NAME": "6Bet Sge",
        "RA": "19H41M002.94S",
        "DEC": "+17D28M033.75S",
        "APPMAG": 4.39,
        "DIST": "439.56LY",
        "SPEC": "G8II"
    },
    {
        "NAME": "25Iot Oph",
        "RA": "16H54M000.47S",
        "DEC": "+10D09M055.29S",
        "APPMAG": 4.39,
        "DIST": "245.23LY",
        "SPEC": "B8V"
    },
    {
        "NAME": "8Eps Mon",
        "RA": "06H23M046.09S",
        "DEC": "+04D35M034.31S",
        "APPMAG": 4.39,
        "DIST": "122.29LY",
        "SPEC": "A5IV"
    },
    {
        "NAME": "Sham",
        "RA": "19H40M005.79S",
        "DEC": "+18D00M050.00S",
        "APPMAG": 4.39,
        "DIST": "425.24LY",
        "SPEC": "G0II"
    },
    {
        "NAME": "31    Leo",
        "RA": "10H07M054.27S",
        "DEC": "+09D59M051.03S",
        "APPMAG": 4.39,
        "DIST": "295.43LY",
        "SPEC": "K4III"
    },
    {
        "NAME": "HIP 17884.0",
        "RA": "03H49M031.29S",
        "DEC": "+65D31M033.50S",
        "APPMAG": 4.39,
        "DIST": "795.50LY",
        "SPEC": "M1III"
    },
    {
        "NAME": "HIP 39311.0",
        "RA": "08H02M015.94S",
        "DEC": "+02D20M004.46S",
        "APPMAG": 4.39,
        "DIST": "254.02LY",
        "SPEC": "K2III"
    },
    {
        "NAME": "16    Pup",
        "RA": "08H09M001.64S",
        "DEC": "-19D14M042.05S",
        "APPMAG": 4.4,
        "DIST": "465.27LY",
        "SPEC": "B5V"
    },
    {
        "NAME": "Del Ind",
        "RA": "21H57M055.05S",
        "DEC": "-54D59M033.27S",
        "APPMAG": 4.4,
        "DIST": "188.09LY",
        "SPEC": "F0IV"
    },
    {
        "NAME": "38Eta And",
        "RA": "00H57M012.40S",
        "DEC": "+23D25M003.53S",
        "APPMAG": 4.4,
        "DIST": "229.69LY",
        "SPEC": "G8III-IV"
    },
    {
        "NAME": "Kap Pav",
        "RA": "18H56M057.04S",
        "DEC": "-67D14M000.58S",
        "APPMAG": 4.4,
        "DIST": "500.24LY",
        "SPEC": "F5Ib-II:"
    },
    {
        "NAME": "Omi Pup",
        "RA": "07H48M005.17S",
        "DEC": "-25D56M013.81S",
        "APPMAG": 4.4,
        "DIST": "1418.07LY",
        "SPEC": "B1IV:nne"
    },
    {
        "NAME": "Maasym",
        "RA": "17H30M044.31S",
        "DEC": "+26D06M038.32S",
        "APPMAG": 4.41,
        "DIST": "369.37LY",
        "SPEC": "K3IIIvar"
    },
    {
        "NAME": "HIP 32761.0",
        "RA": "06H49M051.32S",
        "DEC": "-53D37M020.82S",
        "APPMAG": 4.41,
        "DIST": "544.50LY",
        "SPEC": "G6II"
    },
    {
        "NAME": "94Nu  Her",
        "RA": "17H58M030.15S",
        "DEC": "+30D11M021.40S",
        "APPMAG": 4.41,
        "DIST": "860.57LY",
        "SPEC": "F2II"
    },
    {
        "NAME": "33Pi  Cep",
        "RA": "23H07M053.84S",
        "DEC": "+75D23M014.99S",
        "APPMAG": 4.41,
        "DIST": "246.71LY",
        "SPEC": "G2III"
    },
    {
        "NAME": "46Tau Gem",
        "RA": "07H11M008.37S",
        "DEC": "+30D14M042.59S",
        "APPMAG": 4.41,
        "DIST": "321.02LY",
        "SPEC": "K2III"
    },
    {
        "NAME": "93Psi2Aqr",
        "RA": "23H17M054.21S",
        "DEC": "-09D10M057.05S",
        "APPMAG": 4.41,
        "DIST": "401.67LY",
        "SPEC": "B5Vn"
    },
    {
        "NAME": "66Ups Cyg",
        "RA": "21H17M055.08S",
        "DEC": "+34D53M048.83S",
        "APPMAG": 4.41,
        "DIST": "642.04LY",
        "SPEC": "B2Vne"
    },
    {
        "NAME": "Gam Scl",
        "RA": "23H18M049.44S",
        "DEC": "-32D31M055.30S",
        "APPMAG": 4.41,
        "DIST": "182.21LY",
        "SPEC": "K1III"
    },
    {
        "NAME": "HIP 70300.0",
        "RA": "14H23M002.24S",
        "DEC": "-39D30M042.55S",
        "APPMAG": 4.41,
        "DIST": "457.44LY",
        "SPEC": "B2V"
    },
    {
        "NAME": "HIP 40326.0",
        "RA": "08H14M002.91S",
        "DEC": "-40D20M052.40S",
        "APPMAG": 4.42,
        "DIST": "298.40LY",
        "SPEC": "K1II/III"
    },
    {
        "NAME": "67Nu  Ori",
        "RA": "06H07M034.32S",
        "DEC": "+14D46M006.50S",
        "APPMAG": 4.42,
        "DIST": "516.07LY",
        "SPEC": "B3IV"
    },
    {
        "NAME": "58    Hya",
        "RA": "14H50M017.33S",
        "DEC": "-27D57M037.34S",
        "APPMAG": 4.42,
        "DIST": "331.12LY",
        "SPEC": "K3III"
    },
    {
        "NAME": "68    Oph",
        "RA": "18H01M045.20S",
        "DEC": "+01D18M018.27S",
        "APPMAG": 4.42,
        "DIST": "292.52LY",
        "SPEC": "A2Vn"
    },
    {
        "NAME": "Alkarab",
        "RA": "23H25M022.77S",
        "DEC": "+23D24M014.76S",
        "APPMAG": 4.42,
        "DIST": "170.41LY",
        "SPEC": "F8IV"
    },
    {
        "NAME": "60    Leo",
        "RA": "11H02M019.78S",
        "DEC": "+20D10M047.43S",
        "APPMAG": 4.42,
        "DIST": "126.76LY",
        "SPEC": "A1m"
    },
    {
        "NAME": "8Nu 3CMa",
        "RA": "06H37M053.42S",
        "DEC": "-18D14M014.92S",
        "APPMAG": 4.42,
        "DIST": "421.39LY",
        "SPEC": "K0II/III"
    },
    {
        "NAME": "27Lam Ser",
        "RA": "15H46M026.62S",
        "DEC": "+07D21M011.06S",
        "APPMAG": 4.42,
        "DIST": "39.54LY",
        "SPEC": "G0Vvar"
    },
    {
        "NAME": "HIP 34922.0",
        "RA": "07H13M032.29S",
        "DEC": "-44D38M023.06S",
        "APPMAG": 4.42,
        "DIST": "208.94LY",
        "SPEC": "M5e"
    },
    {
        "NAME": "3Bet Lac",
        "RA": "22H23M033.63S",
        "DEC": "+52D13M044.57S",
        "APPMAG": 4.42,
        "DIST": "169.96LY",
        "SPEC": "G9III"
    },
    {
        "NAME": "27    CMa",
        "RA": "07H14M015.21S",
        "DEC": "-26D21M009.03S",
        "APPMAG": 4.42,
        "DIST": "1734.87LY",
        "SPEC": "B3III"
    },
    {
        "NAME": "Keid",
        "RA": "04H15M016.33S",
        "DEC": "-07D39M010.34S",
        "APPMAG": 4.43,
        "DIST": "16.26LY",
        "SPEC": "K1V"
    },
    {
        "NAME": "26Pi  Eri",
        "RA": "03H46M008.53S",
        "DEC": "-12D06M005.72S",
        "APPMAG": 4.43,
        "DIST": "481.06LY",
        "SPEC": "M1III"
    },
    {
        "NAME": "62    Sgr",
        "RA": "20H02M039.48S",
        "DEC": "-27D42M035.44S",
        "APPMAG": 4.43,
        "DIST": "448.63LY",
        "SPEC": "M4III"
    },
    {
        "NAME": "39    Cyg",
        "RA": "20H23M051.62S",
        "DEC": "+32D11M024.62S",
        "APPMAG": 4.43,
        "DIST": "249.93LY",
        "SPEC": "K3III"
    },
    {
        "NAME": "11Del Del",
        "RA": "20H43M027.53S",
        "DEC": "+15D04M028.49S",
        "APPMAG": 4.43,
        "DIST": "223.24LY",
        "SPEC": "A7IIIp d Del"
    },
    {
        "NAME": "Aladfar",
        "RA": "19H13M045.49S",
        "DEC": "+39D08M045.48S",
        "APPMAG": 4.43,
        "DIST": "1387.90LY",
        "SPEC": "B2.5IV"
    },
    {
        "NAME": "3    Aqr",
        "RA": "20H47M044.24S",
        "DEC": "-05D01M039.72S",
        "APPMAG": 4.43,
        "DIST": "585.56LY",
        "SPEC": "M3IIIvar"
    },
    {
        "NAME": "7    Cam",
        "RA": "04H57M017.21S",
        "DEC": "+53D45M007.56S",
        "APPMAG": 4.43,
        "DIST": "371.90LY",
        "SPEC": "A1V"
    },
    {
        "NAME": "GJ 1109",
        "RA": "08H18M033.33S",
        "DEC": "-36D39M033.44S",
        "APPMAG": 4.44,
        "DIST": "93.37LY",
        "SPEC": "A4m..."
    },
    {
        "NAME": "HIP 40091.0",
        "RA": "08H11M021.49S",
        "DEC": "-39D37M006.76S",
        "APPMAG": 4.44,
        "DIST": "1698.73LY",
        "SPEC": "K4III"
    },
    {
        "NAME": "Eps Ret",
        "RA": "04H16M029.06S",
        "DEC": "-59D18M007.76S",
        "APPMAG": 4.44,
        "DIST": "59.49LY",
        "SPEC": "K2IV"
    },
    {
        "NAME": "7    Cet",
        "RA": "00H14M038.42S",
        "DEC": "-18D55M058.32S",
        "APPMAG": 4.44,
        "DIST": "447.40LY",
        "SPEC": "M1III"
    },
    {
        "NAME": "2    Lyn",
        "RA": "06H19M037.39S",
        "DEC": "+59D00M039.47S",
        "APPMAG": 4.44,
        "DIST": "156.58LY",
        "SPEC": "A2Vs"
    },
    {
        "NAME": "Gl 279",
        "RA": "07H34M003.18S",
        "DEC": "-22D17M045.84S",
        "APPMAG": 4.44,
        "DIST": "82.51LY",
        "SPEC": "F6V"
    },
    {
        "NAME": "Alp Cae",
        "RA": "04H40M033.74S",
        "DEC": "-41D51M049.51S",
        "APPMAG": 4.44,
        "DIST": "65.77LY",
        "SPEC": "F2V"
    },
    {
        "NAME": "63Del Psc",
        "RA": "00H48M040.94S",
        "DEC": "+07D35M006.28S",
        "APPMAG": 4.44,
        "DIST": "311.22LY",
        "SPEC": "K5III"
    },
    {
        "NAME": "Sig Lup",
        "RA": "14H32M037.06S",
        "DEC": "-50D27M025.77S",
        "APPMAG": 4.44,
        "DIST": "575.23LY",
        "SPEC": "B2III"
    },
    {
        "NAME": "Anser",
        "RA": "19H28M042.34S",
        "DEC": "+24D39M053.66S",
        "APPMAG": 4.44,
        "DIST": "297.32LY",
        "SPEC": "M0 comp"
    },
    {
        "NAME": "106Nu  Psc",
        "RA": "01H41M025.89S",
        "DEC": "+05D29M015.41S",
        "APPMAG": 4.45,
        "DIST": "363.20LY",
        "SPEC": "K3III"
    },
    {
        "NAME": "Del2Cha",
        "RA": "10H45M047.11S",
        "DEC": "-80D32M024.68S",
        "APPMAG": 4.45,
        "DIST": "350.71LY",
        "SPEC": "B2.5IV"
    },
    {
        "NAME": "38Mu  Aql",
        "RA": "19H34M005.35S",
        "DEC": "+07D22M044.19S",
        "APPMAG": 4.45,
        "DIST": "107.61LY",
        "SPEC": "K3III"
    },
    {
        "NAME": "Minchir",
        "RA": "08H38M045.44S",
        "DEC": "+03D20M029.17S",
        "APPMAG": 4.45,
        "DIST": "372.75LY",
        "SPEC": "K2III"
    },
    {
        "NAME": "70Xi  Ori",
        "RA": "06H11M056.40S",
        "DEC": "+14D12M031.55S",
        "APPMAG": 4.45,
        "DIST": "607.37LY",
        "SPEC": "B3IV"
    },
    {
        "NAME": "3Iot Lep",
        "RA": "05H12M017.90S",
        "DEC": "-11D52M009.19S",
        "APPMAG": 4.45,
        "DIST": "231.81LY",
        "SPEC": "B8V"
    },
    {
        "NAME": "60Tau Dra",
        "RA": "19H15M033.22S",
        "DEC": "+73D21M019.68S",
        "APPMAG": 4.45,
        "DIST": "146.39LY",
        "SPEC": "K3III"
    },
    {
        "NAME": "Bet For",
        "RA": "02H49M005.41S",
        "DEC": "-32D24M021.23S",
        "APPMAG": 4.45,
        "DIST": "172.66LY",
        "SPEC": "G8III"
    },
    {
        "NAME": "74Phi Leo",
        "RA": "11H16M039.70S",
        "DEC": "-03D39M005.76S",
        "APPMAG": 4.45,
        "DIST": "184.17LY",
        "SPEC": "A7IVn"
    },
    {
        "NAME": "HIP 44191.0",
        "RA": "09H00M005.42S",
        "DEC": "-41D15M012.98S",
        "APPMAG": 4.45,
        "DIST": "210.42LY",
        "SPEC": "Fp"
    },
    {
        "NAME": "HIP 51849.0",
        "RA": "10H35M035.30S",
        "DEC": "-57D33M027.49S",
        "APPMAG": 4.45,
        "DIST": "1177.46LY",
        "SPEC": "K3/K4II"
    },
    {
        "NAME": "9Ome Oph",
        "RA": "16H32M008.20S",
        "DEC": "-21D27M059.00S",
        "APPMAG": 4.45,
        "DIST": "168.64LY",
        "SPEC": "Ap"
    },
    {
        "NAME": "15    UMa",
        "RA": "09H08M052.31S",
        "DEC": "+51D36M016.73S",
        "APPMAG": 4.46,
        "DIST": "93.99LY",
        "SPEC": "Am"
    },
    {
        "NAME": "22Gam PsA",
        "RA": "22H52M031.54S",
        "DEC": "-32D52M031.81S",
        "APPMAG": 4.46,
        "DIST": "215.43LY",
        "SPEC": "A0III"
    },
    {
        "NAME": "Iot Cas",
        "RA": "02H29M003.97S",
        "DEC": "+67D24M008.91S",
        "APPMAG": 4.46,
        "DIST": "132.85LY",
        "SPEC": "A5p Sr"
    },
    {
        "NAME": "17Rho Ori",
        "RA": "05H13M017.48S",
        "DEC": "+02D51M040.55S",
        "APPMAG": 4.46,
        "DIST": "349.95LY",
        "SPEC": "K3III..."
    },
    {
        "NAME": "Eps Nor",
        "RA": "16H27M011.04S",
        "DEC": "-47D33M017.23S",
        "APPMAG": 4.46,
        "DIST": "530.34LY",
        "SPEC": "B4V"
    },
    {
        "NAME": "HIP 59173.0",
        "RA": "12H08M005.24S",
        "DEC": "-50D39M040.60S",
        "APPMAG": 4.46,
        "DIST": "438.38LY",
        "SPEC": "B2IIIne"
    },
    {
        "NAME": "32    Eri",
        "RA": "03H54M017.50S",
        "DEC": "-02D57M017.03S",
        "APPMAG": 4.46,
        "DIST": "313.01LY",
        "SPEC": "G8III"
    },
    {
        "NAME": "11Bet Crt",
        "RA": "11H11M039.49S",
        "DEC": "-22D49M033.05S",
        "APPMAG": 4.46,
        "DIST": "340.10LY",
        "SPEC": "A1V"
    },
    {
        "NAME": "13    Mon",
        "RA": "06H32M054.23S",
        "DEC": "+07D19M058.67S",
        "APPMAG": 4.47,
        "DIST": "326156.38LY",
        "SPEC": "A0Ib"
    },
    {
        "NAME": "26    UMa",
        "RA": "09H34M049.46S",
        "DEC": "+52D03M005.32S",
        "APPMAG": 4.47,
        "DIST": "262.18LY",
        "SPEC": "A2V"
    },
    {
        "NAME": "16    Lib",
        "RA": "14H57M011.00S",
        "DEC": "-04D20M047.26S",
        "APPMAG": 4.47,
        "DIST": "87.75LY",
        "SPEC": "F0V"
    },
    {
        "NAME": "1Kap Leo",
        "RA": "09H24M039.26S",
        "DEC": "+26D10M056.37S",
        "APPMAG": 4.47,
        "DIST": "201.33LY",
        "SPEC": "K2III"
    },
    {
        "NAME": "HIP 44599.0",
        "RA": "09H05M008.83S",
        "DEC": "-72D36M009.74S",
        "APPMAG": 4.47,
        "DIST": "400.68LY",
        "SPEC": "F6II-III"
    },
    {
        "NAME": "HIP 15549.0",
        "RA": "03H20M020.36S",
        "DEC": "+29D02M054.45S",
        "APPMAG": 4.47,
        "DIST": "542.69LY",
        "SPEC": "K2II-III"
    },
    {
        "NAME": "1Tau1Eri",
        "RA": "02H45M006.17S",
        "DEC": "-18D34M021.23S",
        "APPMAG": 4.47,
        "DIST": "46.38LY",
        "SPEC": "F5/F6V"
    },
    {
        "NAME": "7Del Equ",
        "RA": "21H14M028.81S",
        "DEC": "+10D00M025.13S",
        "APPMAG": 4.47,
        "DIST": "60.30LY",
        "SPEC": "F5V+..."
    },
    {
        "NAME": "10Pi 6Ori",
        "RA": "04H58M032.90S",
        "DEC": "+01D42M050.46S",
        "APPMAG": 4.47,
        "DIST": "945.38LY",
        "SPEC": "K2IIvar"
    },
    {
        "NAME": "28Sig Boo",
        "RA": "14H34M040.80S",
        "DEC": "+29D44M042.47S",
        "APPMAG": 4.47,
        "DIST": "51.64LY",
        "SPEC": "F3Vwvar"
    },
    {
        "NAME": "Lam CMa",
        "RA": "06H28M010.21S",
        "DEC": "-32D34M048.25S",
        "APPMAG": 4.47,
        "DIST": "423.58LY",
        "SPEC": "B4V"
    },
    {
        "NAME": "Lam Gru",
        "RA": "22H06M006.89S",
        "DEC": "-39D32M036.07S",
        "APPMAG": 4.47,
        "DIST": "242.14LY",
        "SPEC": "M0III"
    },
    {
        "NAME": "HIP 57803.0",
        "RA": "11H51M008.71S",
        "DEC": "-45D10M024.49S",
        "APPMAG": 4.47,
        "DIST": "433.14LY",
        "SPEC": "K4III"
    },
    {
        "NAME": "HIP 38957.0",
        "RA": "07H58M014.44S",
        "DEC": "-49D14M041.68S",
        "APPMAG": 4.47,
        "DIST": "959.28LY",
        "SPEC": "B1Vp + B2"
    },
    {
        "NAME": "22Omi Cas",
        "RA": "00H44M043.51S",
        "DEC": "+48D17M003.71S",
        "APPMAG": 4.48,
        "DIST": "702.92LY",
        "SPEC": "B5III"
    },
    {
        "NAME": "71    Tau",
        "RA": "04H26M020.74S",
        "DEC": "+15D37M005.75S",
        "APPMAG": 4.48,
        "DIST": "160.12LY",
        "SPEC": "F0V..."
    },
    {
        "NAME": "Gam Ret",
        "RA": "04H00M053.81S",
        "DEC": "-62D09M033.42S",
        "APPMAG": 4.48,
        "DIST": "469.29LY",
        "SPEC": "M4III"
    },
    {
        "NAME": "15Alp Sex",
        "RA": "10H07M056.28S",
        "DEC": "-00D22M017.89S",
        "APPMAG": 4.48,
        "DIST": "283.37LY",
        "SPEC": "A0III"
    },
    {
        "NAME": "Gam Cir",
        "RA": "15H23M022.65S",
        "DEC": "-59D19M014.83S",
        "APPMAG": 4.48,
        "DIST": "448.63LY",
        "SPEC": "B5III + F8"
    },
    {
        "NAME": "86    Aqr",
        "RA": "23H06M040.84S",
        "DEC": "-23D44M035.21S",
        "APPMAG": 4.48,
        "DIST": "216.28LY",
        "SPEC": "G8III"
    },
    {
        "NAME": "18    Mon",
        "RA": "06H47M051.65S",
        "DEC": "+02D24M043.77S",
        "APPMAG": 4.48,
        "DIST": "368.12LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "Fumalsamakah",
        "RA": "23H03M052.61S",
        "DEC": "+03D49M012.16S",
        "APPMAG": 4.48,
        "DIST": "408.21LY",
        "SPEC": "B6Ve"
    },
    {
        "NAME": "4Psi Oph",
        "RA": "16H24M006.18S",
        "DEC": "-20D02M014.38S",
        "APPMAG": 4.48,
        "DIST": "199.48LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "Gl 268.1",
        "RA": "07H12M033.66S",
        "DEC": "-46D45M033.50S",
        "APPMAG": 4.49,
        "DIST": "69.89LY",
        "SPEC": "F0IV"
    },
    {
        "NAME": "30    Gem",
        "RA": "06H43M059.29S",
        "DEC": "+13D13M040.86S",
        "APPMAG": 4.49,
        "DIST": "288.89LY",
        "SPEC": "K1III"
    },
    {
        "NAME": "18Lam Psc",
        "RA": "23H42M002.80S",
        "DEC": "+01D46M048.15S",
        "APPMAG": 4.49,
        "DIST": "106.62LY",
        "SPEC": "A7V"
    },
    {
        "NAME": "HIP 38455.0",
        "RA": "07H52M038.65S",
        "DEC": "-38D51M046.12S",
        "APPMAG": 4.49,
        "DIST": "648.42LY",
        "SPEC": "B2V"
    },
    {
        "NAME": "Eps Tuc",
        "RA": "23H59M054.94S",
        "DEC": "-65D34M037.68S",
        "APPMAG": 4.49,
        "DIST": "373.18LY",
        "SPEC": "B9IV"
    },
    {
        "NAME": "13The Cyg",
        "RA": "19H36M026.54S",
        "DEC": "+50D13M015.97S",
        "APPMAG": 4.49,
        "DIST": "59.80LY",
        "SPEC": "F4V"
    },
    {
        "NAME": "105Ome2Aqr",
        "RA": "23H42M043.34S",
        "DEC": "-14D32M041.66S",
        "APPMAG": 4.49,
        "DIST": "148.52LY",
        "SPEC": "B9V"
    },
    {
        "NAME": "48    Cas",
        "RA": "02H01M057.52S",
        "DEC": "+70D54M025.27S",
        "APPMAG": 4.49,
        "DIST": "115.01LY",
        "SPEC": "A3IV"
    },
    {
        "NAME": "24    Cap",
        "RA": "21H07M007.67S",
        "DEC": "-25D00M021.07S",
        "APPMAG": 4.49,
        "DIST": "456.16LY",
        "SPEC": "K5/M0III"
    },
    {
        "NAME": "29Pi 1Boo",
        "RA": "14H40M043.56S",
        "DEC": "+16D25M005.97S",
        "APPMAG": 4.49,
        "DIST": "305.68LY",
        "SPEC": "B9p MnHg"
    },
    {
        "NAME": "78Mu 1Cyg",
        "RA": "21H44M008.56S",
        "DEC": "+28D44M033.48S",
        "APPMAG": 4.49,
        "DIST": "72.53LY",
        "SPEC": "F6V"
    },
    {
        "NAME": "50Ups1Eri",
        "RA": "04H33M030.56S",
        "DEC": "-29D45M059.37S",
        "APPMAG": 4.49,
        "DIST": "127.06LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "21    LMi",
        "RA": "10H07M025.76S",
        "DEC": "+35D14M040.89S",
        "APPMAG": 4.49,
        "DIST": "92.11LY",
        "SPEC": "A7V"
    },
    {
        "NAME": "4Tau Boo",
        "RA": "13H47M015.76S",
        "DEC": "+17D27M024.86S",
        "APPMAG": 4.5,
        "DIST": "50.94LY",
        "SPEC": "F7V"
    },
    {
        "NAME": "93    Leo",
        "RA": "11H47M059.14S",
        "DEC": "+20D13M008.15S",
        "APPMAG": 4.5,
        "DIST": "232.64LY",
        "SPEC": "A comp SB"
    },
    {
        "NAME": "HIP 50676.0",
        "RA": "10H20M054.81S",
        "DEC": "-56D02M035.59S",
        "APPMAG": 4.5,
        "DIST": "1148.44LY",
        "SPEC": "B3III"
    },
    {
        "NAME": "36    Cap",
        "RA": "21H28M043.40S",
        "DEC": "-21D48M025.85S",
        "APPMAG": 4.5,
        "DIST": "171.12LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "Gam Pic",
        "RA": "05H49M049.62S",
        "DEC": "-56D09M059.99S",
        "APPMAG": 4.5,
        "DIST": "176.78LY",
        "SPEC": "K1III"
    },
    {
        "NAME": "HIP 43105.0",
        "RA": "08H46M042.55S",
        "DEC": "-56D46M011.19S",
        "APPMAG": 4.5,
        "DIST": "605.11LY",
        "SPEC": "B3Vne"
    },
    {
        "NAME": "47Ome Ori",
        "RA": "05H39M011.15S",
        "DEC": "+04D07M017.28S",
        "APPMAG": 4.5,
        "DIST": "1382.02LY",
        "SPEC": "B3IIIe"
    },
    {
        "NAME": "11    Lac",
        "RA": "22H40M030.84S",
        "DEC": "+44D16M034.70S",
        "APPMAG": 4.5,
        "DIST": "332.81LY",
        "SPEC": "K3III"
    },
    {
        "NAME": "HIP 109754.0",
        "RA": "22H13M052.72S",
        "DEC": "+39D42M053.74S",
        "APPMAG": 4.5,
        "DIST": "482.48LY",
        "SPEC": "K3III"
    },
    {
        "NAME": "13Nu  Aqr",
        "RA": "21H09M035.65S",
        "DEC": "-11D22M018.09S",
        "APPMAG": 4.5,
        "DIST": "159.33LY",
        "SPEC": "G8III"
    },
    {
        "NAME": "23    Vul",
        "RA": "20H15M046.14S",
        "DEC": "+27D48M051.27S",
        "APPMAG": 4.5,
        "DIST": "338.69LY",
        "SPEC": "K3III"
    },
    {
        "NAME": "14Mu  PsA",
        "RA": "22H08M023.00S",
        "DEC": "-32D59M018.48S",
        "APPMAG": 4.5,
        "DIST": "135.84LY",
        "SPEC": "A2V"
    },
    {
        "NAME": "83Tau Psc",
        "RA": "01H11M039.63S",
        "DEC": "+30D05M022.70S",
        "APPMAG": 4.51,
        "DIST": "168.82LY",
        "SPEC": "K0III-IV..."
    },
    {
        "NAME": "Del Tuc",
        "RA": "22H27M019.91S",
        "DEC": "-64D57M058.87S",
        "APPMAG": 4.51,
        "DIST": "250.89LY",
        "SPEC": "B8V"
    },
    {
        "NAME": "7Rho Cas",
        "RA": "23H54M023.03S",
        "DEC": "+57D29M057.78S",
        "APPMAG": 4.51,
        "DIST": "326156.38LY",
        "SPEC": "F8Iavar"
    },
    {
        "NAME": "67Rho Dra",
        "RA": "20H02M049.06S",
        "DEC": "+67D52M024.83S",
        "APPMAG": 4.51,
        "DIST": "428.59LY",
        "SPEC": "K3III"
    },
    {
        "NAME": "Eta Ind",
        "RA": "20H44M002.28S",
        "DEC": "-51D55M015.50S",
        "APPMAG": 4.51,
        "DIST": "78.84LY",
        "SPEC": "A6:var"
    },
    {
        "NAME": "25Sig And",
        "RA": "00H18M019.67S",
        "DEC": "+36D47M006.81S",
        "APPMAG": 4.51,
        "DIST": "134.78LY",
        "SPEC": "A2V"
    },
    {
        "NAME": "HIP 47391.0",
        "RA": "09H39M021.02S",
        "DEC": "-61D19M041.02S",
        "APPMAG": 4.51,
        "DIST": "225.71LY",
        "SPEC": "B9V"
    },
    {
        "NAME": "21Iot Ser",
        "RA": "15H41M033.06S",
        "DEC": "+19D40M013.44S",
        "APPMAG": 4.51,
        "DIST": "190.07LY",
        "SPEC": "A1V"
    },
    {
        "NAME": "Eps Ant",
        "RA": "09H29M014.72S",
        "DEC": "-35D57M004.81S",
        "APPMAG": 4.51,
        "DIST": "710.58LY",
        "SPEC": "K3III"
    },
    {
        "NAME": "29Tau Aur",
        "RA": "05H49M010.44S",
        "DEC": "+39D10M051.86S",
        "APPMAG": 4.51,
        "DIST": "206.82LY",
        "SPEC": "G8III"
    },
    {
        "NAME": "39Eps Cap",
        "RA": "21H37M004.83S",
        "DEC": "-19D27M057.64S",
        "APPMAG": 4.51,
        "DIST": "1055.52LY",
        "SPEC": "B3V:p"
    },
    {
        "NAME": "HIP 65387.0",
        "RA": "13H24M000.46S",
        "DEC": "-64D32M008.40S",
        "APPMAG": 4.52,
        "DIST": "260.30LY",
        "SPEC": "G5III-IV"
    },
    {
        "NAME": "Khambalia",
        "RA": "14H19M006.59S",
        "DEC": "-13D22M015.94S",
        "APPMAG": 4.52,
        "DIST": "186.48LY",
        "SPEC": "A1V"
    },
    {
        "NAME": "Lilii Borea",
        "RA": "02H47M054.53S",
        "DEC": "+29D14M049.62S",
        "APPMAG": 4.52,
        "DIST": "171.57LY",
        "SPEC": "K1III"
    },
    {
        "NAME": "Eps Tel",
        "RA": "18H11M013.77S",
        "DEC": "-45D57M015.90S",
        "APPMAG": 4.52,
        "DIST": "418.15LY",
        "SPEC": "G5III"
    },
    {
        "NAME": "46Ups Sgr",
        "RA": "19H21M043.62S",
        "DEC": "-15D57M018.06S",
        "APPMAG": 4.52,
        "DIST": "1782.28LY",
        "SPEC": "F2p"
    },
    {
        "NAME": "6    Lac",
        "RA": "22H30M029.26S",
        "DEC": "+43D07M024.15S",
        "APPMAG": 4.52,
        "DIST": "1716.61LY",
        "SPEC": "B2IV"
    },
    {
        "NAME": "2    Peg",
        "RA": "21H29M056.89S",
        "DEC": "+23D38M019.82S",
        "APPMAG": 4.52,
        "DIST": "393.91LY",
        "SPEC": "M1III"
    },
    {
        "NAME": "43Psi Boo",
        "RA": "15H04M026.75S",
        "DEC": "+26D56M051.54S",
        "APPMAG": 4.52,
        "DIST": "245.97LY",
        "SPEC": "K2III"
    },
    {
        "NAME": "HIP 65271.0",
        "RA": "13H22M037.96S",
        "DEC": "-60D59M018.21S",
        "APPMAG": 4.52,
        "DIST": "354.52LY",
        "SPEC": "B3V"
    },
    {
        "NAME": "GJ 9706",
        "RA": "20H45M021.16S",
        "DEC": "+57D34M047.01S",
        "APPMAG": 4.52,
        "DIST": "89.02LY",
        "SPEC": "F8IV-V"
    },
    {
        "NAME": "17Kap2Boo",
        "RA": "14H13M028.98S",
        "DEC": "+51D47M023.87S",
        "APPMAG": 4.53,
        "DIST": "163.40LY",
        "SPEC": "A8IV"
    },
    {
        "NAME": "35Nu  And",
        "RA": "00H49M048.84S",
        "DEC": "+41D04M044.08S",
        "APPMAG": 4.53,
        "DIST": "617.72LY",
        "SPEC": "B5V SB"
    },
    {
        "NAME": "3    Sgr",
        "RA": "17H47M033.63S",
        "DEC": "-27D49M050.84S",
        "APPMAG": 4.53,
        "DIST": "985.37LY",
        "SPEC": "F7II"
    },
    {
        "NAME": "54Lam Cyg",
        "RA": "20H47M024.54S",
        "DEC": "+36D29M026.58S",
        "APPMAG": 4.53,
        "DIST": "769.24LY",
        "SPEC": "B6IV"
    },
    {
        "NAME": "HIP 85365.0",
        "RA": "17H26M037.88S",
        "DEC": "-05D05M011.75S",
        "APPMAG": 4.53,
        "DIST": "98.09LY",
        "SPEC": "F3V"
    },
    {
        "NAME": "7    And",
        "RA": "23H12M032.98S",
        "DEC": "+49D24M022.35S",
        "APPMAG": 4.53,
        "DIST": "80.20LY",
        "SPEC": "F0V"
    },
    {
        "NAME": "Bet2Tuc",
        "RA": "00H31M033.41S",
        "DEC": "-62D57M056.02S",
        "APPMAG": 4.53,
        "DIST": "168.47LY",
        "SPEC": "A2V"
    },
    {
        "NAME": "HIP 37096.0",
        "RA": "07H37M022.11S",
        "DEC": "-34D58M006.71S",
        "APPMAG": 4.53,
        "DIST": "360.39LY",
        "SPEC": "B8IV/V"
    },
    {
        "NAME": "HIP 28413.0",
        "RA": "06H00M003.35S",
        "DEC": "-03D04M027.31S",
        "APPMAG": 4.53,
        "DIST": "420.85LY",
        "SPEC": "K2IIIvar"
    },
    {
        "NAME": "32Tau2Hya",
        "RA": "09H31M058.93S",
        "DEC": "-01D11M004.79S",
        "APPMAG": 4.54,
        "DIST": "517.71LY",
        "SPEC": "A3V"
    },
    {
        "NAME": "10    LMi",
        "RA": "09H34M013.38S",
        "DEC": "+36D23M051.21S",
        "APPMAG": 4.54,
        "DIST": "185.00LY",
        "SPEC": "G8III"
    },
    {
        "NAME": "55    Peg",
        "RA": "23H07M000.26S",
        "DEC": "+09D24M034.17S",
        "APPMAG": 4.54,
        "DIST": "328.79LY",
        "SPEC": "M2III"
    },
    {
        "NAME": "Phi2Lup",
        "RA": "15H23M009.35S",
        "DEC": "-36D51M030.56S",
        "APPMAG": 4.54,
        "DIST": "519.36LY",
        "SPEC": "B4V"
    },
    {
        "NAME": "37Xi  Boo",
        "RA": "14H51M023.37S",
        "DEC": "+19D06M001.66S",
        "APPMAG": 4.54,
        "DIST": "21.89LY",
        "SPEC": "G8V + K4V"
    },
    {
        "NAME": "16    Aur",
        "RA": "05H18M010.57S",
        "DEC": "+33D22M017.81S",
        "APPMAG": 4.54,
        "DIST": "232.31LY",
        "SPEC": "K3III..."
    },
    {
        "NAME": "24Iot1Lib",
        "RA": "15H12M013.29S",
        "DEC": "-19D47M030.16S",
        "APPMAG": 4.54,
        "DIST": "379.69LY",
        "SPEC": "Asp..."
    },
    {
        "NAME": "24    UMa",
        "RA": "09H34M028.93S",
        "DEC": "+69D49M049.23S",
        "APPMAG": 4.54,
        "DIST": "104.14LY",
        "SPEC": "G4III-IV"
    },
    {
        "NAME": "5Xi 2CMa",
        "RA": "06H35M003.39S",
        "DEC": "-22D57M053.25S",
        "APPMAG": 4.54,
        "DIST": "441.35LY",
        "SPEC": "A0III"
    },
    {
        "NAME": "70    Peg",
        "RA": "23H29M009.29S",
        "DEC": "+12D45M037.99S",
        "APPMAG": 4.54,
        "DIST": "174.88LY",
        "SPEC": "G8III"
    },
    {
        "NAME": "59    Sgr",
        "RA": "19H56M056.83S",
        "DEC": "-27D10M011.64S",
        "APPMAG": 4.54,
        "DIST": "832.03LY",
        "SPEC": "K3III"
    },
    {
        "NAME": "2    Lac",
        "RA": "22H21M001.54S",
        "DEC": "+46D32M011.65S",
        "APPMAG": 4.55,
        "DIST": "554.69LY",
        "SPEC": "B6V"
    },
    {
        "NAME": "6    CMi",
        "RA": "07H29M047.78S",
        "DEC": "+12D00M023.63S",
        "APPMAG": 4.55,
        "DIST": "572.20LY",
        "SPEC": "K2III"
    },
    {
        "NAME": "HIP 88839.0",
        "RA": "18H08M004.98S",
        "DEC": "-28D27M025.53S",
        "APPMAG": 4.55,
        "DIST": "339.04LY",
        "SPEC": "K0IIICNpvar"
    },
    {
        "NAME": "HIP 33694.0",
        "RA": "07H00M003.89S",
        "DEC": "+76D58M038.67S",
        "APPMAG": 4.55,
        "DIST": "183.75LY",
        "SPEC": "K4III"
    },
    {
        "NAME": "4    Lac",
        "RA": "22H24M030.99S",
        "DEC": "+49D28M035.01S",
        "APPMAG": 4.55,
        "DIST": "2249.35LY",
        "SPEC": "B9Iab"
    },
    {
        "NAME": "Gam1Cae",
        "RA": "05H04M024.38S",
        "DEC": "-35D28M058.72S",
        "APPMAG": 4.55,
        "DIST": "181.30LY",
        "SPEC": "K2III"
    },
    {
        "NAME": "HIP 76371.0",
        "RA": "15H35M053.25S",
        "DEC": "-44D57M030.20S",
        "APPMAG": 4.55,
        "DIST": "428.03LY",
        "SPEC": "B3IVp"
    },
    {
        "NAME": "30Phi UMa",
        "RA": "09H52M006.36S",
        "DEC": "+54D03M051.60S",
        "APPMAG": 4.55,
        "DIST": "508.82LY",
        "SPEC": "A3IV"
    },
    {
        "NAME": "19Omi Sco",
        "RA": "16H20M038.18S",
        "DEC": "-24D10M009.55S",
        "APPMAG": 4.55,
        "DIST": "879.13LY",
        "SPEC": "A4II/III"
    },
    {
        "NAME": "2    Cet",
        "RA": "00H03M044.39S",
        "DEC": "-17D20M009.56S",
        "APPMAG": 4.55,
        "DIST": "272.25LY",
        "SPEC": "B9IVn"
    },
    {
        "NAME": "11    Cep",
        "RA": "21H41M055.15S",
        "DEC": "+71D18M041.10S",
        "APPMAG": 4.55,
        "DIST": "182.41LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "HIP 16281.0",
        "RA": "03H29M054.74S",
        "DEC": "+58D52M043.50S",
        "APPMAG": 4.55,
        "DIST": "2508.90LY",
        "SPEC": "A0Ia SB:"
    },
    {
        "NAME": "1Sig Ara",
        "RA": "17H35M039.60S",
        "DEC": "-46D30M020.46S",
        "APPMAG": 4.56,
        "DIST": "378.37LY",
        "SPEC": "A0V"
    },
    {
        "NAME": "31    Vul",
        "RA": "20H52M007.68S",
        "DEC": "+27D05M049.12S",
        "APPMAG": 4.56,
        "DIST": "188.53LY",
        "SPEC": "G8III"
    },
    {
        "NAME": "136    Tau",
        "RA": "05H53M019.64S",
        "DEC": "+27D36M044.14S",
        "APPMAG": 4.56,
        "DIST": "423.03LY",
        "SPEC": "A0V"
    },
    {
        "NAME": "17    Per",
        "RA": "02H51M030.84S",
        "DEC": "+35D03M035.07S",
        "APPMAG": 4.56,
        "DIST": "467.27LY",
        "SPEC": "K5III"
    },
    {
        "NAME": "63    Cyg",
        "RA": "21H06M036.09S",
        "DEC": "+47D38M054.25S",
        "APPMAG": 4.56,
        "DIST": "1032.14LY",
        "SPEC": "K4II"
    },
    {
        "NAME": "HIP 44700.0",
        "RA": "09H06M031.77S",
        "DEC": "+38D27M007.97S",
        "APPMAG": 4.56,
        "DIST": "817.43LY",
        "SPEC": "G8Ib-II"
    },
    {
        "NAME": "Tau1Lup",
        "RA": "14H26M008.23S",
        "DEC": "-45D13M017.13S",
        "APPMAG": 4.56,
        "DIST": "1090.82LY",
        "SPEC": "B2IV"
    },
    {
        "NAME": "Del Ret",
        "RA": "03H58M044.74S",
        "DEC": "-61D24M000.67S",
        "APPMAG": 4.56,
        "DIST": "526.06LY",
        "SPEC": "M2III"
    },
    {
        "NAME": "72    Leo",
        "RA": "11H15M012.23S",
        "DEC": "+23D05M043.81S",
        "APPMAG": 4.56,
        "DIST": "959.28LY",
        "SPEC": "M3III"
    },
    {
        "NAME": "HIP 16870.0",
        "RA": "03H37M005.68S",
        "DEC": "-40D16M028.36S",
        "APPMAG": 4.57,
        "DIST": "230.83LY",
        "SPEC": "K0III"
    },
    {
        "NAME": "Cujam",
        "RA": "16H25M024.95S",
        "DEC": "+14D01M059.77S",
        "APPMAG": 4.57,
        "DIST": "250.12LY",
        "SPEC": "B9p Cr"
    },
    {
        "NAME": "13    Vul",
        "RA": "19H53M027.69S",
        "DEC": "+24D04M046.61S",
        "APPMAG": 4.57,
        "DIST": "334.52LY",
        "SPEC": "B9.5III"
    },
    {
        "NAME": "113    Her",
        "RA": "18H54M044.88S",
        "DEC": "+22D38M042.27S",
        "APPMAG": 4.57,
        "DIST": "472.01LY",
        "SPEC": "G4III+..."
    },
    {
        "NAME": "Dziban",
        "RA": "17H41M056.32S",
        "DEC": "+72D08M055.83S",
        "APPMAG": 4.57,
        "DIST": "74.48LY",
        "SPEC": "F5IV-V"
    },
    {
        "NAME": "5Rho Oph",
        "RA": "16H25M035.12S",
        "DEC": "-23D26M049.84S",
        "APPMAG": 4.57,
        "DIST": "361.19LY",
        "SPEC": "B2V"
    },
    {
        "NAME": "Del CrA",
        "RA": "19H08M020.96S",
        "DEC": "-40D29M048.13S",
        "APPMAG": 4.57,
        "DIST": "178.52LY",
        "SPEC": "K1III"
    },
    {
        "NAME": "Salm",
        "RA": "23H20M038.24S",
        "DEC": "+23D44M025.21S",
        "APPMAG": 4.58,
        "DIST": "161.70LY",
        "SPEC": "A5V"
    },
    {
        "NAME": "HIP 52468.0",
        "RA": "10H43M032.30S",
        "DEC": "-60D33M059.83S",
        "APPMAG": 4.58,
        "DIST": "1140.41LY",
        "SPEC": "K3Ib"
    },
    {
        "NAME": "13    Sco",
        "RA": "16H12M018.21S",
        "DEC": "-27D55M034.94S",
        "APPMAG": 4.58,
        "DIST": "478.94LY",
        "SPEC": "B2V"
    },
    {
        "NAME": "57Mu  Oph",
        "RA": "17H37M050.71S",
        "DEC": "-08D07M007.58S",
        "APPMAG": 4.58,
        "DIST": "754.99LY",
        "SPEC": "B8II-IIIMNp"
    },
    {
        "NAME": "HIP 48374.0",
        "RA": "09H51M040.67S",
        "DEC": "-46D32M051.43S",
        "APPMAG": 4.58,
        "DIST": "1055.52LY",
        "SPEC": "G5Ib"
    },
    {
        "NAME": "HIP 64425.0",
        "RA": "13H12M017.61S",
        "DEC": "-59D55M014.08S",
        "APPMAG": 4.58,
        "DIST": "378.81LY",
        "SPEC": "B8V"
    }
]
]]
