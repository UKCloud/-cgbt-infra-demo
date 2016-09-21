node {

    wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {

    timestamps {

        // Mark the code checkout 'Checkout'....
        stage('Checkout') {
     
            // Get some code from a GitHub repository
            git url: 'https://github.com/UKCloud/cgbt-infra-demo.git'

            // Get the Terraform tool.
            def tfHome = tool name: 'Terraform', type: 'com.cloudbees.jenkins.plugins.customtools.CustomTool'
            env.PATH = "${tfHome}:${env.PATH}"
        }

        def apply_test = false
        def apply_preprod = false
        def apply_prod = false

        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'PreProd-OpenStack-User',
            usernameVariable: 'TF_VAR_OS_USERNAME', passwordVariable: 'TF_VAR_OS_PASSWORD']]) {

        env.DEPLOY_ENV = "test"

        // Mark the code build 'plan'....
        stage('Test: Plan') {

            // Output Terraform version
            sh "terraform --version"
            //Remove the terraform state file so we always start from a clean state
            if (fileExists(".terraform/terraform.tfstate")) {
                sh "rm -rf .terraform/terraform.tfstate"
            }
            if (fileExists("status")) {
                sh "rm status"
            }
            sh "./init"
            sh "terraform get"
            sh "set +e; terraform plan -out=${env.DEPLOY_ENV}.plan.out -var-file ${env.DEPLOY_ENV}/${env.DEPLOY_ENV}.tfvars -detailed-exitcode; echo \$? > status"
            def exitCode = readFile('status').trim()

            echo "Terraform Plan Exit Code: ${exitCode}"
            if (exitCode == "0") {
                currentBuild.result = 'SUCCESS'
            }
            if (exitCode == "1") {
                slackSend channel: '#ukcloud-opensource', color: '#0080ff', message: "Test: Plan Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER} ()"
                currentBuild.result = 'FAILURE'
                error 'Plan failed for Test'
            }
            if (exitCode == "2") {
                stash name: "test-plan", includes: "${env.DEPLOY_ENV}.plan.out"
                //slackSend channel: '#ukcloud-opensource', color: 'good', message: "Plan Awaiting Approval: ${env.JOB_NAME} - ${env.BUILD_NUMBER} ()"
                //try {
                //    input message: 'Apply Plan?', ok: 'Apply'
                    apply_test = true
                //} catch (err) {
                //    slackSend channel: '#ukcloud-opensource', color: 'warning', message: "Plan Discarded: ${env.JOB_NAME} - ${env.BUILD_NUMBER} ()"
                //    apply_test = false
                //    currentBuild.result = 'UNSTABLE'
                //}
            }
        }
     
        stage('Test: Apply') {
            if (apply_test) {

                unstash 'test-plan'
                if (fileExists("status.apply")) {
                    sh "rm status.apply"
                }
                sh 'set +e; terraform apply $DEPLOY_ENV.plan.out; echo \$? > status.apply'
                def applyExitCode = readFile('status.apply').trim()
                if (applyExitCode == "0") {
                    slackSend channel: '#ukcloud-opensource', color: 'good', message: "Test: Changes Applied ${env.JOB_NAME} - ${env.BUILD_NUMBER} ()"    
                } else {
                    slackSend channel: '#ukcloud-opensource', color: 'danger', message: "Test: Apply Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER} ()"
                    currentBuild.result = 'FAILURE'
                }
            }
        }
        }

        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'PreProd-OpenStack-User',
            usernameVariable: 'TF_VAR_OS_USERNAME', passwordVariable: 'TF_VAR_OS_PASSWORD']]) {

        env.DEPLOY_ENV = "preprod"

        // Mark the code build 'plan'....
        stage('PreProd: Plan') {

            // Output Terraform version
            sh "terraform --version"
            //Remove the terraform state file so we always start from a clean state
            if (fileExists(".terraform/terraform.tfstate")) {
                sh "rm -rf .terraform/terraform.tfstate"
            }
            if (fileExists("status")) {
                sh "rm status"
            }
            sh "./init"
            sh "terraform get"
            sh "set +e; terraform plan -out=${env.DEPLOY_ENV}.plan.out -var-file ${env.DEPLOY_ENV}/${env.DEPLOY_ENV}.tfvars -detailed-exitcode; echo \$? > status"
            def exitCode = readFile('status').trim()

            echo "Terraform Plan Exit Code: ${exitCode}"
            if (exitCode == "0") {
                currentBuild.result = 'SUCCESS'
            }
            if (exitCode == "1") {
                slackSend channel: '#ukcloud-opensource', color: '#0080ff', message: "PreProd: Plan Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER} ()"
                currentBuild.result = 'FAILURE'
                error 'Plan failed for PreProd'
            }
            if (exitCode == "2") {
                stash name: "test-plan", includes: "${env.DEPLOY_ENV}.plan.out"
                slackSend channel: '#ukcloud-opensource', color: 'good', message: "PreProd: Plan Awaiting Approval: ${env.JOB_NAME} - ${env.BUILD_NUMBER} ()"
                try {
                    input message: 'Apply Plan?', ok: 'Apply'
                    apply_preprod = true
                } catch (err) {
                    slackSend channel: '#ukcloud-opensource', color: 'warning', message: "PreProd: Plan Discarded: ${env.JOB_NAME} - ${env.BUILD_NUMBER} ()"
                    apply_preprod = false
                    currentBuild.result = 'UNSTABLE'
                }
            }
        }
     
        stage('PreProd: Apply') {
            if (apply_preprod) {

                unstash 'test-plan'
                if (fileExists("status.apply")) {
                    sh "rm status.apply"
                }
                sh 'set +e; terraform apply $DEPLOY_ENV.plan.out; echo \$? > status.apply'
                def applyExitCode = readFile('status.apply').trim()
                if (applyExitCode == "0") {
                    slackSend channel: '#ukcloud-opensource', color: 'good', message: "PreProd: Changes Applied ${env.JOB_NAME} - ${env.BUILD_NUMBER} ()"    
                } else {
                    slackSend channel: '#ukcloud-opensource', color: 'danger', message: "PreProd: Apply Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER} ()"
                    currentBuild.result = 'FAILURE'
                }
            }
        }
        }

    } }
}