#!/bin/bash
#Le script doit être situé dans le répertoire root de l'utilisateur pour l'instant
#variables
journal="$HOME/synjournal.log"
ArbreA="$HOME/synchroniseur/A"
ArbreB="$HOME/synchroniseur/B"

#Status de la synchronisation
Esync="false";

#fonction du synchronisation sur le journal
function Jsync {
if [ $Esync = true ]
then
	#FichierA
	#affichage de la date de synchronisation
	echo "$fichier" >> $journal
	echo "Date de synchronisation : `date`" >> $journal
	#affichage du chemin absolu du fichier dans le journal
	echo "Chemin absolu : `find ./ -name $fichier`" >> $journal
	#Affichage du type de fichier
	echo "Type de fichier : `file $fichier`" >> $journal
	#affichage des droits, taille et date d'accès du fichier
	echo "Infos: `stat $fichier`" >> $journal
	echo "######################################" >> $journal
	
	
	#FichierB
	#affichage de la date de synchronisation
	echo "$fichier2" >> $journal
	echo "Date de synchronisation : `date`" >> $journal
	#affichage du chemin absolu du fichier dans le journal
	echo "Chemin absolu : `find ./ -name $fichier2`" >> $journal
	#Affichage du type de fichier
	echo "Type de fichier : `file $fichier2`" >> $journal
	#affichage des droits, taille et date d'accès du fichier
	echo "Infos: `stat $fichier2`" >> $journal
	echo "######################################" >> $journal
	

	
else
	echo "La synchronisation pour le fichier $fichier à échouée"
fi
	
}

#fonction pour gérer les conflits suite à la synchronisation
function lstcft {
if [ $conflit -ge 1 ]
then
	echo "Des conflits ont été détectés, voici la liste des fichiers concernés"
	cat listcft.txt
	echo "Choisissez les mesures à prendre:"
	echo "1) Afficher les différences entre les fichiers?"
	echo "2) Supprimer les fichiers concernés?"
	echo "3) ne rien faire"
	read choix
	case $choix in
		1) echo ""
		   diff $fichierA $fichierB -s
		   ;;
		2) echo ""
		   echo "La suppression des fichiers va commencer"
		   ;;
		3) echo ""
		   echo "Aucune modification ne sera apportée aux fichiers"
		   exit 1
		   ;;
		*) echo "Désolé, veuillez choisir les options 1, 2 ou 3"
           lstcft
           ;;
	esac

fi
}

#fonction du synchroniseur
function prmain {
#Utilisation d'un case pour tester les différentes possibilités sur les répertoires / copier les fichiers entre le 2 répertoires

for fichierA in $ArbreA/*
do
  echo "Affichage des fichiers de l'arbre A"
  if [ -f "$fichierA" ]
  then
  	basename $fichierA
  fi
  if [ -d "$fichierA" ]
  then
  	echo "$fichierA est un répertoire"
  fi
  for fichierB in $ArbreB/*
	do
	echo "Affichage des fichiers de l'arbre B"
	if [ -f "$fichierB" ]
  	then
  		basename $fichierB
  	fi
  	if [ -d "$fichierB" ]
  	then
  		echo "$fichierB est un répertoire"
  	fi

  case $fichierA in
	0)
	#if [ -d "$fichierA"] && [ -f "$fichierB" ] || [ -f "$fichierA" ] && [ -d "$fichierB" ]
	if [ -d "$fichierA" -a -f "$fichierB" ] || [ -f "$fichierA" -a -d "$fichierB" ]
	then
		echo "Conflit entre $fichierA et $fichierB"
		let conflit++
		touch $HOME/listcft.txt
		if [ -d "$fichierA" -a -f "$fichierB" ]
		then
			echo "$fichierA est un répertoire et $fichierB un fichier"
		fi
		if [ -f "$fichierA" -a -d "$fichierB" ]
		then
			echo "$fichierB est un répertoire et $fichierA un fichier"
		fi
		
		basename $fichierA >> listcft.txt
		basename $fichierB >> listcft.txt
		
	fi
	;;
	1)
	if [ -d "$fichierA" ] && [ -d "$fichierB" ]
	then
		echo "$fichierA et $fichierB sont des répertoires"
		ArbreA="$HOME/synchroniseur/A/$fichierA"
		ArbreA="$HOME/synchroniseur/A/$fichierB"
		prmain
	
	fi
	;;
	2)
	fichierA_date=`stat ./$fichierA | grep Modif | cut -c11-20`
	fichierB_date=`stat ./$fichierB |grep Modif | cut -c11-20`


	fichierA_heure=`stat ./$fichierA | grep Modif | cut -c22-39`
	fichierB_heure=`stat ./$fichierB | grep Modif | cut -c22-39`
	
	#mode -b "brief" pour empêcher l'erreur "trop d'arguments en paramètres"
	fichierA_type=`file -b ./$fichierA`
	fichierB_type=`file -b ./$fichierB`

	fichierA_droits=`stat ./$fichierA | grep Accès | cut -c16-26 | grep /`
	fichierB_droits=`stat ./$fichierB | grep Accès | cut -c16-26 | grep /`

	fichierA_taille=`stat ./$fichierA | grep Taille | cut -c14-24`
	fichierB_taille=`stat ./$fichierB | grep Taille | cut -c14-24`
	
	

	#Utiliser c22-29 pour l'heure pour enlever les milisecondes (c22-39), si la gestion des milisecondes devient trop compliquée
	if [ -f "$fichierA" -a -f "$fichierB" ] && [ $fichierA_date = $fichierB_date ] && [ $fichierA_heure = $fichierB_heure ] && [ $fichierA_type = $fichierB_type ] && [ $fichierA_droits = $fichierB_droits ] && [ $fichierA_taille = $fichierB_taille ]
	then
		echo "La date de modification, les droits, le type et la taille de $fichierA correspondent à celles de $fichierB, la synchronisation est 	réussie"
		$ficher=$fichierA
		$fichier2=$fichierB
		Jsync
		
	fi
	;;
	3)
	positionA=`grep $fichierA $journal`
	positionA=`echo $?`
	positionB=`grep $fichierB $journal`
	positionB=`echo $?`

	if [ -f "$fichierA" ] && [ -f "$fichierB" ]
	#utiliser commande touch
	then
		if [ $positionA = 1 ] && [
		then
			echo "$fichierA n'est pas conforme au journal, il a été modifié"
	
		fi
		if [ $positionB = 1 ]
		then
			echo "$fichierB n'est pas conforme au journal, il a été modifié"
	
		fi
		if [ $positionA = 0 ]
		then
			echo "$fichierA n'est pas présent sur le journal, ajout"
			Jsync
	
		fi
		if [ $positionB = 0 ]
		then
			echo "$fichierB n'est pas présent sur le journal, ajout"
			Jsync
	
		fi
	fi
	;;
	4)
	if [ -f "$fichierA" ] && [ -f "$fichierB" ]
	then
		echo "$fichierA n'est pas conforme au journal, il a été modifié"
		
	fi
	;;
	4)
	if [ -f "$fichierA" ] && [ -f "$fichierB" ]
	then
		echo "$fichierA et $fichierB ne sont pas conforme au journal, ils ont été modifiés"
	fi
	;;
  esac
	done
done
#appel de la fonction pour gérer les conflits
lstcft
}

function Erep {
if [ -e "$ArbreA" ] && [ -d "$ArbreA" ] && [ -e "$ArbreB" ] && [ -d "$ArbreB" ]
then
	echo "Les Arbres A et B existent"
	prmain
else
	echo "Création des arbres A et B"
	mkdir $HOME/synchroniseur
	mkdir $HOME/synchroniseur/A
	mkdir $HOME/synchroniseur/B
	prmain
fi
}


#Création du journal de synchronisation
if [ -f "$journal" ] && [ -e "$journal" ]
then
	echo "journal déjà existant"
	Erep
else
	echo "Le journal n'existe pas, il va maintenant être crée"
	touch $HOME/synjournal.log
	Erep
	
fi






#Lien sources:
#https://stackoverflow.com/questions/5874090/how-to-get-diff-between-all-files-inside-2-folders-that-are-on-the-web
#https://stackoverflow.com/questions/180741/how-to-do-something-to-each-file-in-a-directory-with-a-batch-script
#https://askubuntu.com/questions/315335/bash-command-for-each-file-in-a-folder



#https://www.ionos.fr/digitalguide/serveur/configuration/commandes-linux/
#https://www.computerhope.com/unix/udiff.htm
#https://www.it-connect.fr/comparez-des-fichiers-entre-eux-avec-diff-sous-linux/
#https://www.funix.org/fr/unix/awk.htm
#http://www.shellunix.com/awk.html

REP1=$1
REP2=$2
 
#Le but du test est de récupérer le nombre de lignes
#émises vers la sortie standard via grep -c .
#Si diff émet une ou plusieurs lignes, les dossiers
#sont différents. Sinon ils sont identiques.
if [ $(diff -r $REP1 $REP2 | grep -c .) -gt 0 ]; then
    echo "Les répertoires sont différents"
else
    echo "Les répertoires sont identiques"
fi
