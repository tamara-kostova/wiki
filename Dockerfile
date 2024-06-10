FROM node:18-alpine AS assets

# Install dependencies
RUN apk add --no-cache yarn g++ make python3

# Set the working directory
WORKDIR /wiki

# Copy files
COPY ./client ./client
COPY ./dev ./dev
COPY ./package.json ./package.json
COPY ./.babelrc ./.babelrc
COPY ./.eslintignore ./.eslintignore
COPY ./.eslintrc.yml ./.eslintrc.yml

# Install node modules and build assets
RUN yarn cache clean && yarn --frozen-lockfile --non-interactive && yarn build

# Clean up node modules and reinstall for production
RUN rm -rf /wiki/node_modules && yarn --production --frozen-lockfile --non-interactive

# ===============
# --- Release ---
# ===============
FROM node:18-alpine

# Install packages
RUN apk add --no-cache bash curl git openssh gnupg sqlite

# Create directories and set permissions
RUN mkdir -p /wiki /logs /wiki/data/content && chown -R node:node /wiki /logs

# Set the working directory
WORKDIR /wiki

# Copy the built assets and files from the previous stage
COPY --chown=node:node --from=assets /wiki/client ./client
COPY --chown=node:node --from=assets /wiki/dev ./dev
COPY --chown=node:node --from=assets /wiki/package.json ./package.json
COPY --chown=node:node --from=assets /wiki/.babelrc ./.babelrc
COPY --chown=node:node --from=assets /wiki/.eslintignore ./.eslintignore
COPY --chown=node:node --from=assets /wiki/.eslintrc.yml ./.eslintrc.yml
COPY --chown=node:node --from=assets /wiki/node_modules ./node_modules
COPY --chown=node:node ./server ./server
COPY --chown=node:node ./dev/build/config.yml ./config.yml
COPY --chown=node:node ./LICENSE ./LICENSE

# Set user to node
USER node

# Define volumes
VOLUME ["/wiki/data/content"]

# Expose necessary ports
EXPOSE 3000
EXPOSE 3443

# Set the command to start the server
CMD ["node", "server"]
