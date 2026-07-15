%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%
%%%%%%%%	Clase U-Memoria
%%%%%%%%	Primer Autor: Nikolas Tapia M.
%%%%%%%%	Version: 1.5
%%%%%%%%	Fecha: 21-06-2012
%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%    Modificado por Aidan Hogan 2018/10/04
%%%%%%%%    (Para una propuesta)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\NeedsTeXFormat{LaTeX2e}[2009/09/24]
\ProvidesClass{upropuesta}[2012/06/18]

%% Definicion de Condicionales
\newif\if@swapnum
\newif\if@contnum
\@swapnumfalse
\@contnumtrue

%% Declaracion de Opciones
\DeclareOption{leftnum}{\@swapnumtrue}
\DeclareOption{rightnum}{\@swapnumfalse}
\DeclareOption{contnum}{\@contnumtrue}
\DeclareOption{nocontnum}{\@contnumfalse}
\DeclareOption{uprightd}{\AtEndOfPackage{\DeclareMathSymbol{d}{\mathalpha}{operators}{`d}}}
\DeclareOption{uprighte}{\AtEndOfPackage{\DeclareMathSymbol{e}{\mathalpha}{operators}{`e}}}
\DeclareOption{uprighti}{\AtEndOfPackage{\DeclareMathSymbol{i}{\mathalpha}{operators}{`i}}}
\DeclareOption{upright}{\ExecuteOptions{uprightd,uprighte,uprighti}}

%% Pasar Opciones a clase article
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}
\ProcessOptions\relax
\LoadClass[12pt, openany]{article}

%% Packages necesarios
\RequirePackage[utf8]{inputenc} %Encoding
\RequirePackage[top=2cm, left=3cm, bottom=2cm, right=2cm, paper=letterpaper]{geometry} % Margenes
\RequirePackage{amsmath, amssymb, amsthm, graphicx} % Varios
\RequirePackage[main=spanish, english, es-nolists, es-lcroman]{babel} % Lenguaje
\RequirePackage[hidelinks]{hyperref} % Links y numeracion del PDF
\RequirePackage{listings} % Codigo Fuente
\RequirePackage{pgffor} % foreach
\RequirePackage{comment} % Ocultar pauta
\RequirePackage{graphicx} % Pauta
\RequirePackage{tcolorbox} % Pauta
\RequirePackage{pgfgantt} % Pauta
\tcbuselibrary{breakable,skins}

\newtoggle{guia}
\togglefalse{guia}
\DeclareOption{guia}{\toggletrue{guia}}
\ProcessOptions\relax

\newtoggle{informe}
\togglefalse{informe}
\DeclareOption{informe}{\toggletrue{informe}}
\ProcessOptions\relax



\iftoggle{guia}%
 {\newenvironment{pauta}
  {\begin{tcolorbox}[breakable,skin=enhanced,colback=red!5!white,colframe=black,title={\textbf{Guía (deshabilitar antes de entregar)}}] \parskip=0.5\baselineskip \advance\parskip by 0pt plus 2pt \parindent=0pt}
  {\end{tcolorbox}}}
 {\excludecomment{pauta}}


%% Lenguaje
\addto\captionsspanish{\renewcommand\tablename{Tabla}}
\addto\captionsspanish{\renewcommand\contentsname{Tabla de contenido}}
\addto\captionsspanish{\renewcommand\listtablename{Índice de tablas}}
\addto\captionsspanish{\renewcommand\listfigurename{Índice de ilustraciones}}

%% Interlineado
\RequirePackage{parskip}
\setlength{\parskip}{1em}
\setlength{\parindent}{15pt}

%% Renovar enumerate e itemize
\let\oldenum\enumerate
\let\oldendenum\endenumerate
\renewenvironment{enumerate}{\oldenum\setlength{\parskip}{\smallskipamount}}{\oldendenum}
\let\olditem\itemize
\let\oldenditem\enditemize
\renewenvironment{itemize}{\olditem\setlength{\parskip}{\smallskipamount}}{\oldenditem}

%% Teoremas, proofs, etc
\renewenvironment{proof}[1][\proofname] {\par\pushQED{\qed}\normalfont\topsep6\p@\@plus6\p@\relax\trivlist\item[\hskip\labelsep\scshape\footnotesize#1\@addpunct{.}]\ignorespaces}{\popQED\endtrivlist\@endpefalse}

\newtheoremstyle{miestilo}{\baselineskip}{3pt}{\itshape}{}{\bfseries}{}{.5em}{}
\newtheoremstyle{miobs}{\baselineskip}{3pt}{}{}{\bfseries}{}{.5em}{}
\if@swapnum
	\swapnumbers
\fi
\theoremstyle{miestilo}
\newtheorem{defn}{Definición}[section]
\if@contnum
\newtheorem{teo}[defn]{Teorema}
\newtheorem{cor}[defn]{Corolario}
\newtheorem{lema}[defn]{Lema}
\newtheorem{prop}[defn]{Proposición}
\else
\newtheorem{teo}{Teorema}[section]
\newtheorem{cor}{Corolario}[section]
\newtheorem{lema}{Lema}[section]
\newtheorem{prop}{Proposición}[section]
\fi
\theoremstyle{miobs}
\newtheorem*{ej}{Ejemplo}
\newtheorem*{obs}{Observación}

%% Comandos para la portada
\global\let\@carrera\@empty
\newcommand{\setcarrera}[1]{\def\@carrera{#1}}
\let\carrera\setcarrera
\let\setcarrera\relax

\global\let\@memoria\@empty
\newcommand{\setmemoria}[1]{\def\@memoria{#1}}
\let\memoria\setmemoria
\let\setmemoria\relax

\global\let\@guia\@empty
\newcommand{\setguia}[1]{\def\@guia{#1}}
\let\guia\setguia
\let\setguia\relax

\global\let\@supervisor\@empty
\newcommand{\setsupervisor}[1]{\def\@supervisor{#1}}
\let\supervisor\setsupervisor
\let\setsupervisor\relax

\global\let\@depto\@empty
\newcommand{\setdepto}[1]{\def\@depto{#1}}
\let\depto\setdepto
\let\setdepto\relax

\global\let\@comision\@empty
\newcommand{\setcomision}[1]{\def\@comision{#1}}
\let\comision\setcomision
\let\setcomision\relax

\global\let\@auspicio\@empty
\newcommand{\setauspicio}[1]{\def\@auspicio{#1}}
\let\auspicio\setauspicio
\let\setauspicio\relax

\global\let\@modalidad\@empty
\newcommand{\setmodalidad}[1]{\def\@modalidad{#1}}
\let\modalidad\setmodalidad
\let\setmodalidad\relax

%%Portada
\renewcommand{\maketitle}{
	\begin{titlepage}
		\begin{minipage}{1.6cm}
			\includegraphics[scale=.12]{imagenes/institucion/escudoU2014.pdf}
		\end{minipage}
		\begin{minipage}[t]{12cm}
			UNIVERSIDAD DE CHILE\\FACULTAD DE CIENCIAS FÍSICAS Y MATEMÁTICAS\\\MakeUppercase\@depto
		\end{minipage}

		\vspace{2cm}
		\centering
			\@title

		\vspace{1cm}
			\@memoria\\
			\@carrera
			
		\vspace{1cm}
			\@author
		
		\vspace{1cm}
			MODALIDAD: \\ \@modalidad

		\vspace{1cm}
            \foreach \x [count=\xi] in \@guia {
                \ifnum\xi=1
                    PROFESOR GUÍA:\\
                \else
                    PROFESOR COGUÍA:\\
                \fi
                \x\\
                \vspace{0.5cm}
            }
		
		\if\@supervisor\@empty\else		
			\vspace{1cm}
			SUPERVISOR:\\ \@supervisor
		\fi
			

		\if\@auspicio\@empty\else
		\vfill
			\normalfont
			Este trabajo ha sido parcialmente financiado por \@auspicio
		\fi

		\vfill
			SANTIAGO DE CHILE\\ \MakeUppercase\@date
	\end{titlepage}
}

\depto{DEPARTAMENTO DE CIENCIAS DE LA COMPUTACIÓN}
\carrera{INGENIERO CIVIL EN COMPUTACIÓN}
\iftoggle{informe}
 {\memoria{INFORME FINAL DE CC6908 PARA OPTAR AL TÍTULO DE}}
 {\memoria{PROPUESTA DE TEMA DE MEMORIA PARA OPTAR AL TÍTULO DE}}

%%Estilo del frontmatter
\newcommand{\ps@front}{
	\renewcommand{\thepage}{\roman{page}}
	\renewcommand{\@oddhead}{}
	\renewcommand{\@evenhead}{}
	\renewcommand{\@oddfoot}{\hfill\thepage\hfill}
	\renewcommand{\@evenfoot}{\hfill\thepage\hfill}
}

%\let\oldfrontmatter\frontmatter
\newcommand{\frontmatter}{
	\pagestyle{front}
	\oldfrontmatter
}
%\let\oldfrontmatter\relax

%% Miscelaneos
\newcommand{\A}{\mathcal{A}}
\newcommand{\C}{\mathbb{C}}
\newcommand{\D}{\mathbb{D}}
\newcommand{\E}{\mathbb{E}}
\newcommand{\F}{\mathcal{F}}
\newcommand{\G}{\mathcal{G}}
\renewcommand{\H}{\mathcal{H}}
\newcommand{\K}{\mathcal{K}}
\renewcommand{\L}{\mathcal{L}}
\newcommand{\M}{\mathcal{M}}
\newcommand{\N}{\mathbb{N}}
\renewcommand{\M}{\mathcal{M}}
\renewcommand{\P}{\mathbb{P}}
\newcommand{\Q}{\mathbb{Q}}
\newcommand{\R}{\mathbb{R}}
\renewcommand{\S}{\mathcal{S}}
\newcommand{\T}{\mathcal{T}}
\newcommand{\Z}{\mathbb{Z}}
\newcommand{\1}{\mathbf{1}}
\let\epsilon\varepsilon
