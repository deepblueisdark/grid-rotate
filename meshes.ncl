



begin 
;======================================================================
; mpas_faster_2.ncl
;
; Concepts illustrated:
;   - Drawing a subset of an MPAS-O (ocean) grid
;   - Using special "gsSegments" resource for faster primitive draws
;   - Drawing polylines on a map plot
;   - Drawing cylindrical equidistant or polar stereographic maps
;======================================================================
; This script is identical to mpas_2.ncl, except it uses a resource
; (gsSegments) that is only available in NCL V6.2.0. Use of this
; resource makes the polyline drawing go much faster.
; 
; On a Mac laptop, the "mpas_2.ncl" script took 105.9 CPU seconds,
; while this script took 0.58 CPU seconds.
;======================================================================
;
; These files are loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"







	config=True
	config@centro_lat=53
	config@centro_lon=-8
	config@titulo="MESHES MPAS"
	;grid="/mnt/d/TESE/AVALIA_FRQ_TSM/MESH/x4.163842.TESE.BR.static.nc"
	;grid="/mnt/d/TESE/DIFERENTES_MALHAS/x1.163842/x1.163842.BR.init.nc"
	;grid="/mnt/d/TESE/DIFERENTES_MALHAS/x4.163842/x4.163842.TESE.BR.init.nc"
	;grid="/mnt/d/TESE/DIFERENTES_MALHAS/x6.999426/x6.999426.TESE.BR.init.nc"
	grid="grid.nc"
	
	;grid="/mnt/d/TESE/AVALIA_FRQ_TSM/MESH/x20.835586.grid.nc"
	f=addfile(grid,"r")
	config@figura="mesh_ireland"
	wks = gsn_open_wks("png",config@figura)
	
   config@shapefile="";/mnt/e/OneDrive/OPERACIONAL/SHAPES/TESE_SST/capitulo51/todos_tsm_tese.shp"

  RAD2DEG   = get_r2d("float") ; Radian to Degree


   plot_name = config@figura


print("Oi")
	

;---Read edge and lat/lon information
  verticesOnEdge = f->verticesOnEdge
  lonCell        = f->lonCell * RAD2DEG
  latCell        = f->latCell * RAD2DEG
  lonVertex      = f->lonVertex * RAD2DEG
  latVertex      = f->latVertex * RAD2DEG

;---Start the graphics
      ; send graphics to PNG file

  res                       = True
  res@gsnMaximize           = True
  res@gsnFrame              = False
  res@gsnDraw               = False

  res@mpDataBaseVersion     = "MediumRes"

  res@mpLandFillColor       = "transparent"
  res@mpOceanFillColor      = "transparent"   ; no fill
  res@mpGridAndLimbOn       = True
  res@mpOutlineOn           = True

  res@tiMainString          = config@titulo

  ;if(MAP .eq. "POLAR") then
  ;  res@gsnPolar            = "NH"
  ;  res@mpMinLatF           = 70
  ;  map = gsn_csm_map_polar(wks,res)  ; Create the map, don't draw it.
  ;end if
  

    res@mpProjection          = "Orthographic"
    res@mpCenterLatF          =  config@centro_lat             ; Center over U.S. since this particular MPAS
    res@mpCenterLonF          = config@centro_lon              ; file has a higher resolution over the U.S.
    res@pmTickMarkDisplayMode = "Always" 					   ; better map tickmarks
	res@mpPerimOn              = False
    
	res@mpProjection          = "Orthographic"
    res@mpMinLatF              =  51  ;;;  
    res@mpMaxLatF              =  56
    res@mpMinLonF              =  -12
    res@mpMaxLonF              = -4
    res@mpLimitMode            = "latlon"
	
	res@mpOutlineBoundarySets = "AllBoundaries"
    ;cnres@mpAreaNames          = "Brazil"
    res@mpDataBaseVersion     = "MediumRes"   ; necessary for mpDataSetName to be effective
    res@mpLandFillColor       = "bisque2"
    res@mpDataSetName         = "Earth..4"
	
	
	
	
	
	
	map = gsn_csm_map(wks,res)  							   ; Create the map, don't draw it.




;---Code to attach MPAS edge lines to the existing map
  lnres                     = True
  lnres@gsLineThicknessF    = 0.05             ; default is 1
  lnres@gsLineColor         = "NavyBlue"       ; default is black.
  lnres@gsLineThicknessF    = 0.8              ; intsida de das linhas

;---This is the code for the MPAS grid edges
  esizes = getfilevardimsizes(f,"latEdge")
  nedges = esizes(0)
  print("Number of edges = " + nedges)

  ecx = new((/nedges,2/),double)
  ecy = new((/nedges,2/),double)

  ecx(:,0) = lonVertex(verticesOnEdge(:,0)-1)
  ecx(:,1) = lonVertex(verticesOnEdge(:,1)-1)
  ecy(:,0) = latVertex(verticesOnEdge(:,0)-1)
  ecy(:,1) = latVertex(verticesOnEdge(:,1)-1)

  ii0 = ind((abs(ecx(:,0)-ecx(:,1)).gt.180.and.(ecx(:,0).gt.ecx(:,1))))
  ii1 = ind((abs(ecx(:,0)-ecx(:,1)).gt.180.and.(ecx(:,0).lt.ecx(:,1))))
  ecx(ii0,0) = ecx(ii0,0) - 360.0
  ecx(ii1,1) = ecx(ii1,1) - 360.0

;
; Attach the polylines using special "gsSegments" resource. This
; is *much* faster than attaching every line individually.
;
  start_cpu_time = get_cpu_time()

  ;print("Attaching the polylines...")
  lnres@gsSegments = ispan(0,nedges * 2,2)
  poly = gsn_add_polyline(wks,map,ndtooned(ecx),ndtooned(ecy),lnres)
  	 plres             = True           ; resource list for polylines
    plres@gsLineColor = "red"
	plres@gsLineThicknessF=3.0
  ;polygpm = gsn_add_shapefile_polylines(wks,map,config@shapefile,plres)
;		overlay(map,polygpm) 
 

  draw(map)
  frame(wks)
  end_cpu_time = get_cpu_time()
  print("CPU elapsed time = " + (end_cpu_time-start_cpu_time))
  return(map) 
end




	
