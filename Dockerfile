FROM mhart/alpine-node:10
COPY package.json package-lock.json ./
RUN npm install
COPY . .
RUN npm run build
RUN mv ./dist /public
