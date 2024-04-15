function update {
    param()
    $temp=py -m pip list
    $res=$temp.replace('0','')
    for($x=0; $x -lt 10;$x++){
        $res=$res.replace($x.ToString(),'')
    }
    $res=$res.replace('.','')
    $res=$res.replace('Package                   Version','')
    $res=$res.replace('------------------------- ---------','')
    foreach ($x in $res) {
        py -m pip install --upgrade $x
    }
}

