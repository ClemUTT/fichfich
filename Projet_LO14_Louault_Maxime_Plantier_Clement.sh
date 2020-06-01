#! /bin/bash
#Le script doit être situé dans le répertoire root de l'utilisateur pour l'instant
#variables
journal="/root/./synjournal"
ArbreA="/root/synchroniseur/A"
ArbreB="/root/synchroniseur/B"

#Status de la synchronisation
Esync="false";

#Création du journal de synchronisation
if [ -e -f "$journal"  ]
then
	Erep
else
	echo "Le journal n'existe pas, il va maintenant être crée"
	touch /root/.synjournal.txt
	Erep
fi




###############################################
function Erep(){

if [ -e -d "$ArbreA" ] && [ -e -d "$ArbreB" ]
then
	main
else
	echo "Création des arbres A et B"
	mkdir ./A
	mkdir ./B
	main
fi
}
###############################################


#fonction du synchroniseur
function main(){
#Utilisation d'un case pour tester les différentes possibilités sur les répertoires / copier les fichiers entre le 2 répertoires
case $fichier
esac
	
}


#fonction du synchronisation sur le journal
function Jsync(){
if [ $Esync = true ]
then
	#affichage de la date de synchronisation
	date
	#affichage du chemin obsolu du fichier dans le journal
	find ./ -name $fichier > /root/.synjournal.txt
	#affichage des droits, nom, date, propriétaire, groupe, le type et taille du fichier
	ls -l > /root/.synjournal.txt
else
	echo "La synchronisation pour le fichier $fichier à échouée"
fi
	
}