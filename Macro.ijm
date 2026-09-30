inputDir = getDirectory("C:\Users\20223228\OneDrive - TU Eindhoven\Documents\Vakken\BEP\Cellpose\raw_data\WGA_m0");
fileList = getFileList(inputDir);

for (i = 0; i < fileList.length; i++) {

    if (endsWith(fileList[i], "_PC_20xfluor.tif")) {

        pcName = fileList[i];

        base = replace(pcName, "_PC_20xfluor.tif", "");

        dapiName = base + "_Dapi.tif";
        cy5Name  = base + "_mCherry.tif";

        if (File.exists(inputDir + dapiName) &&
            File.exists(inputDir + cy5Name)) {

            open(inputDir + cy5Name);
            rename("Cy5");

            open(inputDir + pcName);
            rename("PC");

            open(inputDir + dapiName);
            rename("DAPI");

            run("Merge Channels...",
                "c1=Cy5 c2=PC c3=DAPI create keep");

            run("Make Composite")inputDir = getDirectory("C:\\Users\\20223228\\OneDrive - TU Eindhoven\\Documents\\Vakken\\BEP\\Cellpose\\raw_data\\WGA_m0");
fileList = getFileList(inputDir);

for (i = 0; i < fileList.length; i++) {

    if (endsWith(fileList[i], "_PC_20xfluor.tif")) {

        pcName = fileList[i];

        base = replace(pcName, "_PC_20xfluor.tif", "");

        dapiName = base + "_Dapi.tif";
        cy5Name  = base + "_mCherry.tif";

        if (File.exists(inputDir + dapiName) &&
            File.exists(inputDir + cy5Name)) {

            open(inputDir + cy5Name);
            rename("Cy5");

            open(inputDir + pcName);
            rename("PC");

            open(inputDir + dapiName);
            rename("DAPI");

            run("Merge Channels...",
                "c1=Cy5 c2=PC c3=DAPI create keep");

            run("Make Composite");

            saveAs("Tiff",
                inputDir + base + "_composite3.tif");

            close("*");
        }
    }
};

            saveAs("Tiff",
                inputDir + base + "_composite3.tif");

            close("*");
        }
    }
}
