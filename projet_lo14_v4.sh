#!/bin/bash

#debeug
#set -xv

#Le script doit être situé dans le répertoire $HOME

#variables
journal="$HOME/synjournal.log"
ArbreA="$HOME/synchroniseur/A"
ArbreB="$HOME/synchroniseur/B"

#Initialisation de du booléen conflit
conflit=0;

#Status de la synchronisation
Esync="false";

#fonction du synchronisation sur le journal
function Jsync {
if [ $Esync = true ]
then
	
	#$fichierA sera celui inscrit dans le journal et servant de référence
	journalA_date=$fichierA_date
	journalA_heure=$fichierA_heure
	journalA_type=$fichierA_type
	journalA_droits=$fichierA_droits
	journalA_taille=$fichierA_taille
	
	
	#FichierA
	#affichage de la date de synchronisation
	echo "$fichierA" >> $journal
	echo "Date de synchronisation : `date`" >> $journal
	#affichage du chemin absolu du fichier dans le journal
	echo "Chemin absolu : `find ./ -name $fichierA`" >> $journal
	#Affichage du type de fichier
	echo "Type: $journalA_type" >> $journal
	#affichage des droits, taille et date d'accès du fichier
	echo "Infos:" >> $journal
	echo "Date: $journalA_date" >> $journal
	echo "Heure: $journalA_heure" >> $journal
	echo "Droits: $journalA_droits" >> $journal
	echo "Taille: $journalA_taille" >> $journal
	echo "######################################" >> $journal
	
else
	echo "La synchronisation pour le fichier $fichier à échouée"
fi
	
}

function lstcft {
echo "conflit : $conflit"
if [ $conflit = 1 ]
then
	echo "Des conflits ont été détectés, voici la liste des fichiers concernés"
	cat $HOME/listcft.txt
	echo "Choisissez les mesures à prendre:"
	echo "1) Afficher les différences entre les fichiers?"
	echo "2) Supprimer les fichiers concernés?"
	echo "3) ne rien faire"
	read choix
	case $choix in
		1) echo ""
		   diff $fichierA $fichierB -s
		   lstcft
		   ;;
		2) echo ""
		   echo "La suppression des fichiers va commencer"
			while read fich; do
				rm $fich
			done <$HOME/listcft.txt
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
echo "Affichage des fichiers de l'arbre A"
for fichierA in $ArbreA/*
do
  if [ -f "$fichierA" ]
  then
  	basename $fichierA
  fi
  if [ -d "$fichierA" ]
  then
  	echo "$fichierA est un répertoire"
  fi

echo "Affichage des fichiers de l'arbre B"
for fichierB in $ArbreB/*
do
	if [ -f "$fichierB" ]
  	then
  		basename $fichierB
  	fi
  	if [ -d "$fichierB" ]
  	then
  		echo "$fichierB est un répertoire"
  	fi

	echo "fichierA = $fichierA"
	echo "fichierB= $fichierB"

	#On vérifie si chaque fichier de l'arbre A est présent dans le journal, si non, on l'indique
	positionA=`grep $fichierA $journal`	
	positionA=`echo $?`
	positionB=`grep $fichierB $journal`
	positionB=`echo $?`


	if [ $positionA = 1 ]
	then
		echo "$fichierA n'est pas présent sur le journal, ajout"
		Jsync
	
	fi
	if [ $positionB = 1 ]
	then
		echo "$fichierB n'est pas présent sur le journal, ajout"
		Jsync
	
	fi

	#Si $fichierA est un fichier et $fichierB un répertoire, il y a conflit.
	if [ -d "$fichierA" -a -f "$fichierB" ] || [ -f "$fichierA" -a -d "$fichierB" ]
	then
		echo "Conflit entre $fichierA et $fichierB"
		$conflit = 1
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
	
	#fichierA et fichierB étant des répertoires, on descend dans l'arborescense
	if [ -d "$fichierA" ] && [ -d "$fichierB" ]
	then
		echo "$fichierA et $fichierB sont des répertoires"
		ArbreA="$HOME/synchroniseur/A/$fichierA"
		ArbreA="$HOME/synchroniseur/A/$fichierB"
		prmain
	
	fi
	

	#si les deux fichiers sont bien des fichiers, et qu'ils ont le même contenu ainsi que les même métadonnées, alors la synchronisation est réussie
	diff=`diff $fichierA $fichierB`
	diff=`echo $?`

	fichierA_nom=`basename $fichierA`
	fichierB_nom=`basename $fichierB`
	
	fichierA_date=`stat $fichierA | grep Modif | cut -c11-20`
	fichierB_date=`stat $fichierB |grep Modif | cut -c11-20`


	fichierA_heure=`stat $fichierA | grep Modif | cut -c22-29`
	fichierB_heure=`stat $fichierB | grep Modif | cut -c22-29`
	
	#mode -b "brief" pour empêcher l'erreur "trop d'arguments en paramètres, tr -d pour supprimer les espaces et ainsi éviter la casse"
	fichierA_type=`file -b $fichierA | tr -d ' '`
	fichierB_type=`file -b $fichierB | tr -d ' '`

	fichierA_droits=`stat $fichierA | grep Accès | cut -c16-26 | grep /`
	fichierB_droits=`stat $fichierB | grep Accès | cut -c16-26 | grep /`

	fichierA_droits_N=`stat $fichierA | grep Accès | cut -c12-15 | grep '^0'`
	fichierB_droits_N=`stat $fichierB | grep Accès | cut -c12-15 | grep '^0'`

	fichierA_taille=`stat $fichierA | grep Taille | cut -c14-24`
	fichierB_taille=`stat $fichierB | grep Taille | cut -c14-24`
	
	

	#Utiliser c22-29 pour l'heure pour enlever les milisecondes (c22-39), si la gestion des milisecondes devient trop compliquée
	if [ -f "$fichierA" -a -f "$fichierB" ] && [ "$diff" = 0 ] && [ "$fichierA_date" = "$fichierB_date" ] && [ "$fichierA_heure" = "$fichierB_heure" ] && [ "$fichierA_type" = "$fichierB_type" ] && [ "$fichierA_droits" = "$fichierB_droits" ] && [ "$fichierA_taille" = "$fichierB_taille" ] && [ "$fichierA_nom" = "$fichierB_nom" ]
	then
		echo "La date de modification, les droits, le type et la taille de $fichierA correspondent à celles de $fichierB, la synchronisation est réussie"
		Jsync
		
	fi
	
	
	#Si les fichiers sont bien des fichiers, mais que les métadonnées de B et A différents par rapport au journal ou inversement, alors on copie les métadonnées du fichier qui est en accord
	#avec le journal sur le fichier qui ne l'est pas

	#De plus, si le contenu d'un fichier diffère de celui qui est conforme au journal, alors le contenu de celui conforme est copié sur celui non conforme
	
	if [ -f "$fichierA" ] && [ -f "$fichierB" ]
	then
		if [ "$positionA" = 0 ] && [ "$diff" = 0 ] && [ "$fichierA_nom" = "$fichierB_nom" ] && [ "$fichierA_date" != "$journalA_date" ] || [ "$fichierA_heure" != "$journalA_heure" ] || [ "$fichierA_type" != "$journalA_type" ] || [ "$fichierA_droits" != "$journalA_droits" ] || [ "$fichierA_taille" != "$journalA_taille" ] && [ "$fichierB_date" = "$journalA_date" ] && [ "$fichierB_heure" = "$journalA_heure" ] && [ "$fichieB_type" = "$journalA_type" ] && [ "$fichierB_droits" = "$journalA_droits" ] && [ "$fichierB_taille" = "$journalA_taille" ]
		then
			echo "$fichierA n'est pas conforme au journal, il a été modifié, $fichierB est lui conforme"
			touch -r $fichierA $fichierB
			if [ "$fichierA_droits" != "$fichierB_droits" ]
			then
				echo "Application des droits de $fichierB à $fichierA"
				chmod $fichierB_droits_N $fichierA
			fi
	
		fi


		if [ "$positionA" = 0 ] && [ "$diff" = 1 ] && [ "$fichierA_nom" = "$fichierB_nom" ] && [ "$fichierA_date" != "$journalA_date" ] || [ "$fichierA_heure" != "$journalA_heure" ] || [ "$fichierA_type" != "$journalA_type" ] || [ "$fichierA_droits" != "$journalA_droits" ] || [ "$fichierA_taille" != "$journalA_taille" ] && [ "$fichierB_date" = "$journalA_date" ] && [ "$fichierB_heure" = "$journalA_heure" ] && [ "$fichieB_type" = "$journalA_type" ] && [ "$fichierB_droits" = "$journalA_droits" ] && [ "$fichierB_taille" = "$journalA_taille" ]
		then
			echo "$fichierA n'est pas conforme au journal, il a été modifié, $fichierB est lui conforme"
			if [ "$fichierA_droits" != "$fichierB_droits" ]
			then
				echo "Application des droits de $fichierB à $fichierA"
				chmod $fichierB_droits_N $fichierA
			fi
			echo "$fichierA et $fichierB n'ont pas le même contenu, $fichierA va être remplacé par le contenu de $fichierB"
			cp $fichierB $fichierA
			touch -r $fichierA $fichierB
	
		fi


		if [ "$positionB" = 0 ] && [ "$diff" = 0 ] && [ "$fichierA_nom" = "$fichierB_nom" ] && [ "$fichierB_date" != "$journalB_date" ] || [ "$fichierB_heure" != "$journalB_heure" ] || [ "$fichierB_type" != "$journalB_type" ] || [ "$fichierB_droits" != "$journalB_droits" ] || [ "$fichierB_taille" != "$journalB_taille" ] && [ "$fichierA_date" = "$journalA_date" ] && [ "$fichierA_heure" = "$journalA_heure" ] && [ "$fichierA_type" = "$journalA_type" ] && [ "$fichierA_droits" = "$journalA_droits" ] && [ "$fichierA_taille" = "$journalA_taille" ]
		then
			echo "$fichierB n'est pas conforme au journal, il a été modifié, $fichierA est lui conforme"
			if [ "$fichierB_droits" != "$fichierA_droits" ]
			then
				echo "Application des droits de $fichierA à $fichierB"
				chmod $fichierA_droits_N $fichierB
			fi	
			touch -r $fichierB $fichierA
	
		fi


		if [ "$positionB" = 0 ] && [ "$diff" = 1 ] && [ "$fichierA_nom" = "$fichierB_nom" ] && [ "$fichierB_date" != "$journalB_date" ] || [ "$fichierB_heure" != "$journalB_heure" ] || [ "$fichierB_type" != "$journalB_type" ] || [ "$fichierB_droits" != "$journalB_droits" ] || [ "$fichierB_taille" != "$journalB_taille" ] && [ "$fichierA_date" = "$journalA_date" ] && [ "$fichierA_heure" = "$journalA_heure" ] && [ "$fichierA_type" = "$journalA_type" ] && [ "$fichierA_droits" = "$journalA_droits" ] && [ "$fichierA_taille" = "$journalA_taille" ]
		#mettre les autres métadonnées après $fichierA_nom pour vérifier si A = B en métadonnées autre que le nom ( a voir )
		then
			echo "$fichierB n'est pas conforme au journal, il a été modifié, $fichierA est lui conforme"
			if [ "$fichierB_droits" != "$fichierA_droits" ]
			then
				echo "Application des droits de $fichierA à $fichierB"
				chmod $fichierA_droits_N $fichierB
			fi
			echo "$fichierA et $fichierB n'ont pas le même contenu, $fichierB va être remplacé par le contenu de $fichierA"
			cp $fichierA $fichierB
			touch -r $fichierB $fichierA
	
		fi

	fi
	

	#Si les deux fichiers ne sont pas conformes aux informations du journal, alors il y a un conflit.
	if [ -f "$fichierA" ] && [ -f "$fichierB" ] && [ "$fichierA_nom" = "$fichierB_nom" ] && [ "$fichierB_date" != "$journalB_date" ] || [ "$fichierB_heure" != "$journalA_heure" ] || [ "$fichierB_type" != "$journalA_type" ] || [ "$fichierB_droits" != "$journalA_droits" ] || [ "$fichierB_taille" != "$journalA_taille" ] && [ "$fichierA_date" != "$journalA_date" ] || [ "$fichierA_heure" != "$journalA_heure" ] || [ "$fichierA_type" != "$journalA_type" ] || [ "$fichierA_droits" != "$journalA_droits" ] || [ "$fichierA_taille" != "$journalA_taille" ]
	then
		echo "conflit repéré $fichierA et $fichierB ne sont pas conforme au journal"
	fi
	
#appel de la fonction pour gérer les conflits
done
done
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

#REP1=$1
#REP2=$2
 
#Le but du test est de récupérer le nombre de lignes
#émises vers la sortie standard via grep -c .
#Si diff émet une ou plusieurs lignes, les dossiers
#sont différents. Sinon ils sont identiques.
#if [ $(diff -r $REP1 $REP2 | grep -c .) -gt 0 ]; then
#    echo "Les répertoires sont différents"
#else
#    echo "Les répertoires sont identiques"
#fi










for $fichierA in $ArbreA
	for $fichierB in $ArbreB

		#Si $fichierA et $fichierB sont différents
			#On les ajoute au journal s'ils existent pas
			break
		#Sinon on fait toute la procédure de vérification de contenu, 			 métadonnées...		

	done
done
