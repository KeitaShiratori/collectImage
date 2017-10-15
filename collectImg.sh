#!/bin/sh
inputfile=input/$1/aucid.txt
workdir=work/$1
outdir=output/b2photo2017${1}shiratori

rm -rf ${workdir}
rm -rf ${outdir}

mkdir ${workdir}
mkdir ${outdir}

removelist=input/$1/remove.txt
rm -f ${removelist}
workidx=0
outidx=0
outflg=false

cat ${inputfile} | while read aucid
do
  if [ -z ${aucid} ] ; then
    continue
  fi

  url=https://page.auctions.yahoo.co.jp/jp/auction/${aucid}

  # ファイルから読み込んだURLにアクセスしてワークディレクトリに保存
  workidx=$(( workidx + 1 ))
  echo ${url}
  filename=${workdir}/${workidx}.html
  curl -o ${filename} ${url}

  # オークション継続中判定
  isAuction=`grep "Button Button--buynow js-modal-show rapidnofollow" ${filename} | wc -l`
  if [ $isAuction -gt 0 ] ; then
    # オークション継続中
    echo "auction is true"
  else
    # オークション終了
    noBids=`grep property=\"auction:Bids\"\>0\</b\> ${filename} | wc -l`
    if [ $noBids = 0 ] ; then
      # 入札がある場合
      echo "auction is ended and exists bids. skip process and do next."
      echo ${aucid} >> ${removelist}
      continue
    fi
  fi

  # 画像読み込み
  imgCount=`grep https://auctions.c.yimg.jp/images.auctions.yahoo.co.jp/image/ ${filename} | grep ^\<img | wc -l`
  if [ ${imgCount} -gt 0 ] ; then
    outidx=$(( outidx + 1 ))
  else
    echo ${aucid} >> ${removelist}
  fi
  suffix=
  grep https://auctions.c.yimg.jp/images.auctions.yahoo.co.jp/image/ ${filename} | grep ^\<img | sed -e 's/[^"]*"\([^"]*\)".*/\1/' | while read imgurl
  do
    echo ${imgurl}
    curl -o ${workdir}/${workidx}${suffix}.jpg ${imgurl}
    cp -p ${workdir}/${workidx}${suffix}.jpg ${outdir}/${outidx}${suffix}.jpg
    if [ -z ${suffix} ] ; then
      suffix=a
    elif [ ${suffix} = a ] ; then
      suffix=b
    else
      break
    fi
  done
done

