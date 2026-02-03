#!/bin/bash
# Script final d'installation MOLOCH - Version Corrigée (Sahel)
set -e

# 1. Configuration des répertoires
export BASE_DIR="$HOME/moloch"
export SRC_DIR="$BASE_DIR/src"
export BIN_DIR="$BASE_DIR/bin"
export DOMAIN_DIR="$BASE_DIR/domain/sahel_d01"

mkdir -p $SRC_DIR $BIN_DIR $DOMAIN_DIR
cd $SRC_DIR

echo "--- Étape 1 : Vérification des dépendances ---"
# 2. Téléchargement des sources (si absent)
[ ! -d "libaec" ] && git clone https://github.com/erget/libaec.git
[ ! -d "eccodes" ] && git clone https://github.com/ecmwf/eccodes.git
[ ! -d "globo-bolam-moloch" ] && git clone https://gitlab.com/isac-meteo/globo-bolam-moloch.git

# 3. Compilation de libaec
echo "--- Étape 2 : Compilation de libaec ---"
cd $SRC_DIR/libaec && mkdir -p build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$BIN_DIR/libaec ..
make -j$(nproc) install

# 4. Compilation d'ecCodes
echo "--- Étape 3 : Compilation d'ecCodes avec support CURL ---"
cd $SRC_DIR/eccodes && rm -rf build && mkdir -p build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$BIN_DIR/eccodes \
         -DENABLE_AEC=ON \
         -DAEC_INCLUDE_DIR=$BIN_DIR/libaec/include \
         -DAEC_LIBRARY=$BIN_DIR/libaec/lib/libaec.so \
         -DENABLE_NETCDF=ON \
         -DENABLE_FORTRAN=ON \
         -DNetCDF_C_LIBRARY=/usr/lib/x86_64-linux-gnu/libnetcdf.so \
         -DNetCDF_FORTRAN_LIBRARY=/usr/lib/x86_64-linux-gnu/libnetcdff.so \
         -DCMAKE_EXE_LINKER_FLAGS="-lcurl" \
         -DCMAKE_SHARED_LINKER_FLAGS="-lcurl"
make -j$(nproc) install

# 5. Préparation de dimensions.inc
echo "--- Étape 4 : Configuration des dimensions ---"
cd $SRC_DIR/globo-bolam-moloch/moloch
cat <<EOF > dimensions.inc
      INTEGER, PARAMETER :: gnlon = 102
      INTEGER, PARAMETER :: gnlat = 102
      INTEGER, PARAMETER :: nlev  = 50
      INTEGER, PARAMETER :: nlevg = 50
      INTEGER, PARAMETER :: nsoil = 7
      INTEGER, PARAMETER :: nprocsx = 1
      INTEGER, PARAMETER :: nprocsy = 1
EOF
cp dimensions.inc $SRC_DIR/globo-bolam-moloch/sources/moloch/
cp dimensions.inc $SRC_DIR/globo-bolam-moloch/sources/common/

# 6. Compilation globale (PRE, MODEL, POST)
echo "--- Étape 5 : Compilation de la chaîne MOLOCH ---"
export FC=gfortran
export FC_MPI=mpif90
export USE_MPI=YES
export DIR_MOL=$SRC_DIR/globo-bolam-moloch/sources/moloch
export DIR_COM=$SRC_DIR/globo-bolam-moloch/sources/common
export LIB_ECC="-L$BIN_DIR/eccodes/lib -leccodes -leccodes_f90"
export INC_ECC="-I$BIN_DIR/eccodes/include"

# On définit les drapeaux de compilation pour corriger les erreurs de lignes trop longues
export FLAGS_FIX="-O2 -I. $INC_ECC -ffree-line-length-none -fallow-argument-mismatch -w"

for COMP in executable_premodel executable_model executable_postmodel
do
    echo ">> Compilation de $COMP"
    cd $SRC_DIR/globo-bolam-moloch/moloch/$COMP

    # Correction des Makefiles
    sed -i "s|\$(HOME)/sources/moloch|$DIR_MOL|g" Makefile
    sed -i "s|\$(HOME)/sources/common|$DIR_COM|g" Makefile

    cp $SRC_DIR/globo-bolam-moloch/moloch/dimensions.inc .

    make clean || true

    make FC=$FC FC_MPI=$FC_MPI USE_MPI=$USE_MPI \
         DIR_SOURCES_MOLOCH=$DIR_MOL \
         DIR_SOURCES_COMMON=$DIR_COM \
         LDFLAGS="$LIB_ECC" \
         FCFLAGS="$FLAGS_FIX" \
         FCFLAGS_MPI="$FLAGS_FIX -Dmpi" -j$(nproc)
done

# 7. Déploiement
echo "--- Étape 6 : Mise en service du domaine ---"
cd $DOMAIN_DIR
ln -sf $SRC_DIR/globo-bolam-moloch/moloch/executable_premodel/premoloch .
ln -sf $SRC_DIR/globo-bolam-moloch/moloch/executable_model/moloch .
ln -sf $SRC_DIR/globo-bolam-moloch/moloch/executable_postmodel/postmoloch .

cp $DIR_MOL/premoloch_an_example.inp ./premoloch.inp
cp $DIR_MOL/moloch_an_example.inp ./moloch.inp
cp $DIR_MOL/postmoloch_an_example.inp ./postmoloch.inp
# AJOUT : Copie de sauvegarde du fichier dimensions pour référence
cp $SRC_DIR/globo-bolam-moloch/moloch/dimensions.inc ./dimensions.inc

echo "===================================================="
echo "      INSTALLATION TERMINÉE AVEC SUCCÈS !          "
echo "  Dossier de travail : $DOMAIN_DIR                 "
echo "===================================================="
