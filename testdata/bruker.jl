using Glob
using Printf


#=
    Calculates offset based on one of two methods:
        1) Temperature dependent chemical shift of Water
        2) Given chemical shift of Proton Dimension (Direct Dimension)
=#

function offset(o1::Float64,o2::Float64,n2,temp::Float16,ppmW::Float64=0.0)
    tempC=temp-273.15
    if tempC < 0.0
        tempC=tempC+273
    end
    if ppmW == 0.0
        ppmW=5.06-0.0122*tempC+0.0000211*tempC*tempC
    end
    gamma=0.101329118
    if n2 == "15N"
        println(n2)
        gamma=0.101329118
    elseif n2 == "13C"
        gamma=0.251449530
    end
    ppm2=offset_calc(o1,o2,ppmW,gamma)
    return @sprintf("%0.3f",ppmW), @sprintf("%0.3f",ppm2)
end


# Calculate the offset in ppm of one frequency based on the ppm and gyromagnetic ratio of another

function offset_calc(o1::Float64, o2::Float64, ppm1::Float64, gamma::Float64)
    o10=o1/(1.0+ppm1*10^-6)
    o20=o10*gamma
    ppm2=(o2/o20-1.0)*10^6
    return ppm2
end

#Read in Metadata from Bruker File
function read_acqfiles(in::String)
    contents=read(in,String)
    values=eachmatch(r"##\$?(.*?)=\s?([^\n]+)"s,contents)
    params = Dict(v.captures[1]=>v.captures[2] for v in values)
    return params
end


# Reads in Spectrometer Metadata from acqus file

function read_acqus()
    params = ["DECIM","DSPFVS","GRPDLY","TE"]
    pars = read_acqfiles("acqus")
    data = Dict(p=>pars[p] for p in params)
    return Dict("DECIM"=>data["DECIM"], "DSPFVS"=>data["DSPFVS"], "GRPDLY"=>data["GRPDLY"], "Temp"=>data["TE"])
end

# Reads in Channel specific Metadata from acqu#s file

function read_params(file::String)
    params = ["SFO1","NUC1","O1","SW_h","TD","FnMODE"]
    fnModes = Dict("0"=>"DQD","1"=>"QF","2"=>"QSEQ","3"=>"TPPI","4"=>"States","5"=>"States-TPPI","6"=>"Echo-AntiEcho")
    pars = read_acqfiles(file)
    data = Dict(p=>pars[p] for p in params)
    return Dict("nLAB"=>strip(data["NUC1"],['<','>']), "nOBS"=>data["SFO1"], "Offset"=>data["O1"],"nSW"=>data["SW_h"],"nN"=>data["TD"],"nMode"=>fnModes[data["FnMODE"]])
end


# FID.com for a 2D experiment

function write_fid_2D(direct,indirect,spectrom)
    open("fid.com","w") do f
        write(f,"#!/bin/csh\n")
        write(f,"\n")
        write(f,"bruk2pipe -in ./ser \\\n")
        write(f," -bad 0.0 -ext -aswap -AMX -decim $(spectrom["DECIM"]) -dspfvs $(spectrom["DSPFVS"]) -grpdly $(spectrom["GRPDLY"]) \\\n")
        write(f," -xN \t$(direct["nN"]) -yN \t$(indirect["nN"]) \\\n")
        write(f," -xT \t$(@sprintf("%.0f",round(parse(Int,direct["nN"])/2))) -yT \t$(@sprintf("%.0f",round(parse(Int,indirect["nN"])/2))) \\\n")
        write(f," -xMODE \t$(direct["nMode"]) -yMODE \t$(indirect["nMode"]) \\\n")
        write(f," -xSW \t$(direct["nSW"]) -ySW \t$(indirect["nSW"]) \\\n")
        write(f," -xOBS \t$(direct["nOBS"]) -yOBS \t$(indirect["nOBS"]) \\\n")
        write(f," -xCAR \t$(direct["ppm"]) -yCAR \t$(indirect["ppm"])  \\\n")
        write(f," -xLAB \t$(direct["nLAB"]) -yLAB \t$(indirect["nLAB"]) \\\n")
        write(f," -ndim \t 2 -aq2D \t States \\\n")
        write(f," -out ./test.fid -verb -ov\n")
        write(f,"\n")
        write(f,"sleep 5")
    end
end


# FID.com for a 3D experiment

function write_fid_3D(direct,indirect,indirect2,spectrom)
    open("fid.com","w") do f
        write(f,"#!/bin/csh\n")
        write(f,"\n")
        write(f,"bruk2pipe -in ./ser \\\n")
        write(f," -bad 0.0 -ext -aswap -AMX -decim $(spectrom["DECIM"]) -dspfvs $(spectrom["DSPFVS"]) -grpdly $(spectrom["GRPDLY"]) \\\n")
        write(f," -xN \t$(direct["nN"]) -yN \t$(indirect["nN"]) -zN \t$(indirect2["nN"]) \\\n")
        write(f," -xT \t$(@sprintf("%.0f",round(parse(Int,direct["nN"])/2))) -yT \t$(@sprintf("%.0f",round(parse(Int,indirect["nN"])/2))) -zT \t$(@sprintf("%.0f",round(parse(Int,indirect2["nN"])/2))) \\\n")
        write(f," -xMODE \t$(direct["nMode"]) -yMODE \t$(indirect["nMode"]) -zMODE \t$(indirect2["nMode"]) \\\n")
        write(f," -xSW \t$(direct["nSW"]) -ySW \t$(indirect["nSW"]) -zSW \t$(indirect2["nSW"]) \\\n")
        write(f," -xOBS \t$(direct["nOBS"]) -yOBS \t$(indirect["nOBS"]) -zOBS \t$(indirect2["nOBS"]) \\\n")
        write(f," -xCAR \t$(direct["ppm"]) -yCAR \t$(indirect["ppm"]) -zCAR \t$(indirect2["ppm"]) \\\n")
        write(f," -xLAB \t$(direct["nLAB"])x -yLAB \t$(indirect["nLAB"])y -zLAB \t$(indirect2["nLAB"])z \\\n")
        write(f," -ndim \t 3 -aq2D \t States \\\n")
        write(f," -out ./fid/test%03d.fid -verb -ov\n")
        write(f,"\n")
        write(f,"sleep 5")
    end
end

###########Main Code#########

# Read in Bruker Acquisition Parameters
files=glob("acqu*s")

# Determine the number of dimensions (2 or 3)
fnum=length(files)

#Write FID.com for 2D or 3D
if fnum == 2
    direct=read_params("acqus")
    indirect=read_params("acqu2s")
    spectrom=read_acqus()
    direct["ppm"], indirect["ppm"]= offset(parse(Float64,direct["nOBS"]),parse(Float64,indirect["nOBS"]),indirect["nLAB"],parse(Float16,spectrom["Temp"]))
    write_fid_2D(direct,indirect,spectrom)
elseif fnum == 3
    direct=read_params("acqus")
    indirect=read_params("acqu2s")
    indirect2=read_params("acqu3s")
    spectrom=read_acqus()
    direct["ppm"], indirect["ppm"]= offset(parse(Float64,direct["nOBS"]),parse(Float64,indirect["nOBS"]),indirect["nLAB"],parse(Float16,spectrom["Temp"]))
    direct["ppm"], indirect2["ppm"]= offset(parse(Float64,direct["nOBS"]),parse(Float64,indirect2["nOBS"]),indirect2["nLAB"],parse(Float16,spectrom["Temp"]))
    write_fid_3D(direct,indirect,indirect2,spectrom)
end

#Run FID.com
chmod("fid.com",0o777)
run(`./fid.com`)
