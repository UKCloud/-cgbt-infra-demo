def slackMessage(String color, String message) {
    slackSend channel: '#ukcloud-opensource', color: "${color}", message: "<${env.BUILD_URL}|[${env.JOB_NAME} - build ${env.BUILD_NUMBER}]> ${message}"
}

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

        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'Test-OpenStack-User',
            usernameVariable: 'TF_VAR_OS_USERNAME', passwordVariable: 'TF_VAR_OS_PASSWORD']]) {

        env.DEPLOY_ENV = "test"

        // Mark the code build 'plan'....
        stage('Test: Deploy') {

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
                slackMessage('#0080ff', 'Test: Plan Failed')
                currentBuild.result = 'FAILURE'
                error 'Plan failed for Test'
            }
            if (exitCode == "2") {
                stash name: "test-plan", includes: "${env.DEPLOY_ENV}.plan.out"
                apply_test = true
            }

            if (apply_test) {

                unstash 'test-plan'
                if (fileExists("status.apply")) {
                    sh "rm status.apply"
                }
                sh 'set +e; terraform apply $DEPLOY_ENV.plan.out; echo \$? > status.apply'
                def applyExitCode = readFile('status.apply').trim()
                if (applyExitCode == "0") {
                    slackMessage('good', 'Test: Changes Applied')
                } else {
                    slackMessage('danger', 'Test: Apply Failed')
                    currentBuild.result = 'FAILURE'
                    error 'Apply failed for Test'
                }
            }
        }

        stage('Test: Regression Tests') {
            if (fileExists("status.regression")) {
                sh "rm status.regression"
            }

            sh 'terraform output jumpbox_address > jumpbox.address'
            def jumpbox = readFile('jumpbox.address').trim()
            echo "Running tests via jumpbox ${jumpbox}"

            sh 'set +e; bundle install; bundle exec rake -t spec; echo \$? > status.regression'
            def testsExitCode = readFile('status.regression').trim()
            if (testsExitCode == "0") {
                slackMessage('good', 'Test: Regression Tests Successful')
            } else {
                slackMessage('danger', 'Test: Regression Tests Failed')
                currentBuild.result = 'FAILURE'
                error 'Regression Testing Failed'
            }
        }
        }

        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'PreProd-OpenStack-User',
            usernameVariable: 'TF_VAR_OS_USERNAME', passwordVariable: 'TF_VAR_OS_PASSWORD']]) {

        env.DEPLOY_ENV = "preprod"

        // Mark the code build 'plan'....
        stage('PreProd: Deploy') {

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
                slackMessage('#0080ff', 'PreProd: Plan Failed')
                currentBuild.result = 'FAILURE'
                error 'Plan failed for PreProd'
            }
            if (exitCode == "2") {
                stash name: "preprod-plan", includes: "${env.DEPLOY_ENV}.plan.out"
                apply_preprod = true
            }

            if (apply_preprod) {

                unstash 'preprod-plan'
                if (fileExists("status.apply")) {
                    sh "rm status.apply"
                }
                sh 'set +e; terraform apply $DEPLOY_ENV.plan.out; echo \$? > status.apply'
                def applyExitCode = readFile('status.apply').trim()
                if (applyExitCode == "0") {
                    slackMessage('good', 'PreProd: Changes Applied')
                } else {
                    slackMessage('danger', 'PreProd: Apply Failed')
                    currentBuild.result = 'FAILURE'
                    error 'PreProd: Apply Failed'
                }
            }
        }
        }

        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'Production-OpenStack-User',
            usernameVariable: 'TF_VAR_OS_USERNAME', passwordVariable: 'TF_VAR_OS_PASSWORD']]) {

        env.DEPLOY_ENV = "production"

        // Mark the code build 'plan'....
        stage('Production: Plan') {

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
                slackMessage('#0080ff', 'Production: Plan Failed')
                currentBuild.result = 'FAILURE'
                error 'Plan failed for Production'
            }
            if (exitCode == "2") {
                stash name: "production-plan", includes: "${env.DEPLOY_ENV}.plan.out"
                slackMessage('good', 'Production: Plan Awaiting Approval')
                try {
                    input message: 'Apply Plan?', ok: 'Apply'
                    apply_prod = true
                } catch (err) {
                    slackMessage('warning', 'Production: Plan Discarded')
                    apply_prod = false
                    currentBuild.result = 'UNSTABLE'
                }
            }
        }
     
        stage('Production: Apply') {
            if (apply_prod) {

                unstash 'production-plan'
                if (fileExists("status.apply")) {
                    sh "rm status.apply"
                }
                sh 'set +e; terraform apply $DEPLOY_ENV.plan.out; echo \$? > status.apply'
                def applyExitCode = readFile('status.apply').trim()
                if (applyExitCode == "0") {
                    slackMessage('good', 'Production: Changes Applied')
                } else {
                    slackMessage('danger', 'Production: Apply Failed')
                    currentBuild.result = 'FAILURE'
                }
            }
        }
        }

    } }
}
