FROM tjamet/hugo AS build

COPY . /src/
WORKDIR /src
RUN hugo

FROM nginx:alpine
COPY --from=build /src/public/ /usr/share/nginx/html/
