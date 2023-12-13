#!/usr/bin/env nextflow
nextflow.enable.dsl=2


process get_images {
  stageInMode 'symlink'
  stageOutMode 'move'

  script:
    """

    if [[ "${params.containers}" == "singularity" ]] ; 

      then

        cd ${params.image_folder}

        if [[ ! -f drugz-eb15d34.sif ]] ;
          then
            singularity pull drugz-eb15d34.sif docker://index.docker.io/mpgagebioinformatics/drugz:eb15d34
        fi

    fi


    if [[ "${params.containers}" == "docker" ]] ; 

      then

        docker pull mpgagebioinformatics/drugz:eb15d34

    fi

    """

}

process prodrugz {
  stageInMode 'symlink'
  stageOutMode 'move'
  
  input:
    val f
  
  script:
    """
    if [[ "${paired}" == "paired" ]] ; then paired="" ; else paired="-unpaired" ; fi

    /drugz/drugz.py -i ${params.ouput_mageck_count}/counts.count.txt -o ${params.output_drugz}/${label}.txt -c ${control} -x ${treatment} \${paired}
    """
}

workflow images {
  main:
    get_images()
}


workflow {
    if ( ! file("${params.output_drugz}").isDirectory() ) {
      file("${params.output_drugz}").mkdirs()
    }

    rows=Channel.fromPath("${params.samples_tsv}", checkIfExists:true).splitCsv(sep:';')
    rows=rows.filter{ ! file( "${params.output_drugz}/${it[0]}.txt" ).exists() }
    label=rows.flatMap { n -> n[0] }
    paired=rows.flatMap { n -> n[1] }
    control=rows.flatMap { n -> n[2] }
    control=control.map{ "$it".replace(".fastq.gz","") }
    treatment=rows.flatMap { n -> n[3] }
    treatment=treatment.map{ "$it".replace(".fastq.gz","") }

    prodrugz( label, paired, control, treatment, paired)

}