with import <nixpkgs> {};

let
  version = "git";
  name = "waistline-${version}";
  androidsdk = androidenv.androidsdk {
    platformVersions = [ "24" "27" ];
    abiVersions = [ "armeabi-v7a" "x86_64"];
    useGoogleAPIs = true;
  };
  jdk = jdk8;
  chromedriver_2_13 = pkgs.chromedriver.overrideAttrs (super: rec {
    name = "chromedriver-${version}";
    version = "2.13";

    src = fetchurl {
      url = "https://chromedriver.storage.googleapis.com/${version}/chromedriver_linux64.zip";
      sha256 = "1m3vmm3wdn58kgn3fnmb9rypxamjgjkh7jzdjz2scd7w9mvlzs01";
    };
  });

  chromedriver_2_23 = pkgs.chromedriver.overrideAttrs (super: rec {
    name = "chromedriver-${version}";
    version = "2.23";

    src = fetchurl {
      url = "https://chromedriver.storage.googleapis.com/${version}/chromedriver_linux64.zip";
      sha256 = "1z5bnx29fxsasq8aan1jp0l6jxifymvd9p29qanl49vpb89fgfnr";
    };
  });

  chromedriver_2_34 = pkgs.chromedriver.overrideAttrs (super: rec {
    name = "chromedriver-${version}";
    version = "2.34";

    src = fetchurl {
      url = "https://chromedriver.storage.googleapis.com/${version}/chromedriver_linux64.zip";
      sha256 = "0ryrq4myjw247s88hbi8nj4p9hqq88mplwn7yxg58fwcwbwmaap4";
    };
  });

  chromedriver = chromedriver_2_34;

  src = pkgs.fetchFromGitHub {
    owner = "davidhealey";
    repo = "waistline";
    rev = "master";
    sha256 = "1121zh7pqcza0maqzi3shc1649v1q3ypwpl0bdpqpjp8jgpa4z3l";
  };

  deps = stdenv.mkDerivation {
    name = "${name}-deps";
    inherit src;
    buildInputs = [ gradle perl ];
    ANDROID_HOME = "${androidsdk}/libexec";

    buildPhase = ''
      export GRADLE_USER_HOME=$(mktemp -d)
      ( cd platforms/android
        HOME=$(mktemp -d) gradle --no-daemon build
      )
    '';
    # perl code mavenizes pathes (com.squareup.okio/okio/1.13.0/a9283170b7305c8d92d25aff02a6ab7e45d06cbe/okio-1.13.0.jar -> com/squareup/okio/okio/1.13.0/okio-1.13.0.jar)
    installPhase = ''
      find $GRADLE_USER_HOME/caches/modules-2 -type f -regex '.*\.\(jar\|pom\|aar\)' \
        | perl -pe 's#(.*/([^/]+)/([^/]+)/([^/]+)/[0-9a-f]{30,40}/([^/\s]+))$# ($x = $2) =~ tr|\.|/|; "install -Dm444 $1 \$out/$x/$3/$4/$5" #e' \
        | sh
    '';
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    outputHash = "0xqvc8bzdl012g8nwd87vvdc5vmfqai91q356mp0fkhxdvxshxh1";
  };

  gradleInit = writeText "init.gradle" ''
    logger.lifecycle 'Replacing Maven repositories with ${deps}...'

    gradle.projectsLoaded {
      rootProject.allprojects {
        buildscript {
          repositories {
            clear()
            maven { url '${deps}' }
          }
        }
        repositories {
          clear()
          maven { url '${deps}' }
        }
      }
    }
  '';

in stdenv.mkDerivation {

  inherit name src;

  ANDROID_HOME = "${androidsdk}/libexec";
  JAVA_HOME = jdk;

  buildInputs = [
    androidsdk
    nodejs
    jdk
    gradle
    chromedriver
  ];

  postPatch = ''
    patchShebangs platforms/android/cordova/build
    ln -sf ${gradle}/bin/gradle platforms/android/gradlew
  '';

  buildPhase = ''
    ./platforms/android/cordova/build \
      --gradleArg=--offline \
      --gradleArg=--no-daemon \
      --gradleArg=--init-script=${gradleInit} \
      -v
  '';
  installPhase = ''
    mkdir $out
    cp -r platforms/android/app/build/outputs $out
  '';

  passthru = { inherit deps; };
}
