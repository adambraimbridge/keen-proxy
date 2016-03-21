clean:
	git clean -fxd

install:
	npm install

deploy-prod:
	next-build-tools deploy-vcl -e --service FASTLY_SERVICE_ID --main main.vcl ./vcl/
