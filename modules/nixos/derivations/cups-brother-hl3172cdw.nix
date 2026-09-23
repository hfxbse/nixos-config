{
  a2ps,
  autoPatchelfHook,
  coreutils,
  cups,
  dpkg,
  fetchurl,
  file,
  gawk,
  ghostscript,
  glibc,
  gnused,
  makeWrapper,
  lib,
  pkgsi686Linux,
  ...
}:
let
  model = "hl3172cdw";
  cupsVersion = "1.1.4-0";
  lprVersion = "1.1.3-0";
  version = "1.1.4-0";
  cupsDeb = fetchurl {
    url = "https://download.brother.com/welcome/dlf101637/${model}cupswrapper-${cupsVersion}.i386.deb";
    sha256 = "39eed80ddb5c7432e0aceffcb3cb0378fc773c50f8bbe528db7d11bd3b9ceb10";
  };
  srcDir = "${model}_cupswrapper_GPL_source_${version}";
  cupsSrc = fetchurl {
    url = "https://download.brother.com/welcome/dlf101646/${srcDir}.tar.gz";
    sha256 = "1844ede1865bbffbefb3b167672168cc50129e57ce02688a2a9d22af54d7c060";
  };
  lprDeb = fetchurl {
    url = "https://download.brother.com/welcome/dlf101636/${model}lpr-${lprVersion}.i386.deb";
    sha256 = "e651ec39297daf7e5d5e36537c836b9d1c52d36873f2c5a4c28b46226b3e0d9d";
  };
in
pkgsi686Linux.stdenv.mkDerivation {
  pname = "cups-brother-${model}";
  version = cupsVersion;

  nativeBuildInputs = [
    makeWrapper
    dpkg
    autoPatchelfHook
  ];
  buildInputs = [
    cups
    ghostscript
    a2ps
    glibc
  ];

  unpackPhase = ''
    tar -xvf ${cupsSrc}
  '';

  buildPhase = ''
    gcc -Wall ${srcDir}/brcupsconfig/brcupsconfig.c -o brcupsconfpt1
  '';

  installPhase = ''
    mkdir -p $out/lib/cups/filter

    # Install LPR
    dpkg-deb -x ${lprDeb} $out

    substituteInPlace $out/opt/brother/Printers/${model}/lpd/filter${model}  --replace /opt "$out/opt"
    substituteInPlace $out/opt/brother/Printers/${model}/inf/setupPrintcapij --replace /opt "$out/opt"

    sed -i '/GHOST_SCRIPT=/c\GHOST_SCRIPT=gs' $out/opt/brother/Printers/${model}/lpd/psconvertij2

    wrapProgram $out/opt/brother/Printers/${model}/lpd/psconvertij2 --prefix PATH ":" ${
      lib.makeBinPath [
        gnused
        coreutils
        gawk
      ]
    }
    wrapProgram $out/opt/brother/Printers/${model}/lpd/filter${model} --prefix PATH ":" ${
      lib.makeBinPath [
        ghostscript
        a2ps
        file
        gnused
        coreutils
      ]
    }

    ln -s $out/opt/brother/Printers/${model}/lpd/filter${model} $out/lib/cups/filter/brother_lpdwrapper_${model}

    # Install CUPS
    dpkg-deb -x ${cupsDeb} $out
    substituteInPlace $out/opt/brother/Printers/${model}/cupswrapper/cupswrapper${model} --replace /opt "$out/opt"

    ln -s $out/opt/brother/Printers/${model}/cupswrapper/cupswrapper${model} $out/lib/cups/filter/cupswrapper${model}

    cp brcupsconfpt1 $out/opt/brother/Printers/${model}/cupswrapper/
    ln -s $out/opt/brother/Printers/${model}/cupswrapper/brcupsconfpt1 $out/lib/cups/filter/brcupsconfpt1

    wrapProgram $out/opt/brother/Printers/${model}/cupswrapper/cupswrapper${model} --prefix PATH ":" ${
      lib.makeBinPath [
        gnused
        coreutils
        gawk
      ]
    }

    # Install PPD file
    mkdir -p $out/share/cups/model/
    cp ${srcDir}/PPD/brother_${model}_printer_en.ppd $out/share/cups/model/
  '';

  meta = {
    homepage = "http://www.brother.com/";
    description = "Brother ${model} printer driver";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    license = lib.licenses.unfree;
    platforms = lib.platforms.linux;
    architectures = [ "x86" ];
    downloadPage = "https://support.brother.com/g/b/downloadlist.aspx?c=eu_ot&lang=en&prod=${model}_eu&os=128";
  };
}
