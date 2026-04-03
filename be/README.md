[16:09:47] Starting compilation in watch mode...

src/batteries/batteries.service.ts:188:9 - error TS2353: Object literal may only specify known properties, and 'auctions' does not exist in type 'BatteryInclude<DefaultArgs>'.

188         auctions: {
            ~~~~~~~~

  node_modules/.prisma/client/index.d.ts:8671:5
    8671     include?: BatteryInclude<ExtArgs> | null
             ~~~~~~~
    The expected type comes from property 'include' which is declared here on type '{ select?: BatterySelect<DefaultArgs> | null | undefined; omit?: BatteryOmit<DefaultArgs> | null | undefined; include?: BatteryInclude<...> | ... 1 more ... | undefined; where: BatteryWhereUniqueInput; }'

src/batteries/batteries.service.ts:405:11 - error TS2353: Object literal may only specify known properties, and 'auctions' does not exist in type 'BatteryInclude<DefaultArgs>'.

405           auctions: {
              ~~~~~~~~

src/bids/bids.service.ts:172:13 - error TS2353: Object literal may only specify known properties, and 'vehicle' does not exist in type 'AuctionInclude<DefaultArgs>'.

172             vehicle: true,
                ~~~~~~~

src/bids/bids.service.ts:366:13 - error TS2353: Object literal may only specify known properties, and 'vehicle' does not exist in type 'AuctionInclude<DefaultArgs>'.

366             vehicle: true,
                ~~~~~~~

src/moderation/content-moderation.service.ts:120:36 - error TS2339: Property 'LFP' does not exist on type '{ LITHIUM_ION: "LITHIUM_ION"; LITHIUM_POLYMER: "LITHIUM_POLYMER"; NICKEL_METAL_HYDRIDE: "NICKEL_METAL_HYDRIDE"; LEAD_ACID: "LEAD_ACID"; }'.

120         batteryType ?? BatteryType.LFP,
                                       ~~~

src/moderation/content-moderation.service.ts:236:13 - error TS2353: Object literal may only specify known properties, and 'vehicleId' does not exist in type 'AuctionWhereInput'.

236             vehicleId: hasVehicle ? { not: null } : undefined,
                ~~~~~~~~~

  node_modules/.prisma/client/index.d.ts:9482:5
    9482     where?: AuctionWhereInput
             ~~~~~
    The expected type comes from property 'where' which is declared here on type 'Subset<AuctionAggregateArgs<DefaultArgs>, AuctionAggregateArgs<DefaultArgs>>'

src/moderation/content-moderation.service.ts:243:13 - error TS2353: Object literal may only specify known properties, and 'batteryId' does not exist in type 'AuctionWhereInput'.

243             batteryId: hasBattery ? { not: null } : undefined,
                ~~~~~~~~~

  node_modules/.prisma/client/index.d.ts:9482:5
    9482     where?: AuctionWhereInput
             ~~~~~
    The expected type comes from property 'where' which is declared here on type 'Subset<AuctionAggregateArgs<DefaultArgs>, AuctionAggregateArgs<DefaultArgs>>'

src/moderation/content-moderation.service.ts:250:37 - error TS18048: 'vehicleAuctions._avg' is possibly 'undefined'.

250       const vehicleAverage = Number(vehicleAuctions._avg.startingPrice ?? 0);
                                        ~~~~~~~~~~~~~~~~~~~~

src/moderation/content-moderation.service.ts:255:37 - error TS18048: 'batteryAuctions._avg' is possibly 'undefined'.

255       const batteryAverage = Number(batteryAuctions._avg.startingPrice ?? 0);
                                        ~~~~~~~~~~~~~~~~~~~~

src/vehicles/vehicles.service.ts:244:11 - error TS2353: Object literal may only specify known properties, and 'auctions' does not exist in type 'VehicleInclude<DefaultArgs>'.

244           auctions: {
              ~~~~~~~~

src/vehicles/vehicles.service.ts:290:9 - error TS2353: Object literal may only specify known properties, and 'auctions' does not exist in type 'VehicleInclude<DefaultArgs>'.

290         auctions: {
            ~~~~~~~~

  node_modules/.prisma/client/index.d.ts:7168:5
    7168     include?: VehicleInclude<ExtArgs> | null
             ~~~~~~~
    The expected type comes from property 'include' which is declared here on type '{ select?: VehicleSelect<DefaultArgs> | null | undefined; omit?: VehicleOmit<DefaultArgs> | null | undefined; include?: VehicleInclude<...> | ... 1 more ... | undefined; where: VehicleWhereUniqueInput; }'

[16:09:51] Found 11 errors. Watching for file changes.<p align="center">
  <a href="http://nestjs.com/" target="blank"><img src="https://nestjs.com/img/logo-small.svg" width="120" alt="Nest Logo" /></a>
</p>

[circleci-image]: https://img.shields.io/circleci/build/github/nestjs/nest/master?token=abc123def456
[circleci-url]: https://circleci.com/gh/nestjs/nest

  <p align="center">A progressive <a href="http://nodejs.org" target="_blank">Node.js</a> framework for building efficient and scalable server-side applications.</p>
    <p align="center">
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/v/@nestjs/core.svg" alt="NPM Version" /></a>
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/l/@nestjs/core.svg" alt="Package License" /></a>
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/dm/@nestjs/common.svg" alt="NPM Downloads" /></a>
<a href="https://circleci.com/gh/nestjs/nest" target="_blank"><img src="https://img.shields.io/circleci/build/github/nestjs/nest/master" alt="CircleCI" /></a>
<a href="https://discord.gg/G7Qnnhy" target="_blank"><img src="https://img.shields.io/badge/discord-online-brightgreen.svg" alt="Discord"/></a>
<a href="https://opencollective.com/nest#backer" target="_blank"><img src="https://opencollective.com/nest/backers/badge.svg" alt="Backers on Open Collective" /></a>
<a href="https://opencollective.com/nest#sponsor" target="_blank"><img src="https://opencollective.com/nest/sponsors/badge.svg" alt="Sponsors on Open Collective" /></a>
  <a href="https://paypal.me/kamilmysliwiec" target="_blank"><img src="https://img.shields.io/badge/Donate-PayPal-ff3f59.svg" alt="Donate us"/></a>
    <a href="https://opencollective.com/nest#sponsor"  target="_blank"><img src="https://img.shields.io/badge/Support%20us-Open%20Collective-41B883.svg" alt="Support us"></a>
  <a href="https://twitter.com/nestframework" target="_blank"><img src="https://img.shields.io/twitter/follow/nestframework.svg?style=social&label=Follow" alt="Follow us on Twitter"></a>
</p>
  <!--[![Backers on Open Collective](https://opencollective.com/nest/backers/badge.svg)](https://opencollective.com/nest#backer)
  [![Sponsors on Open Collective](https://opencollective.com/nest/sponsors/badge.svg)](https://opencollective.com/nest#sponsor)-->

## Description

[Nest](https://github.com/nestjs/nest) framework TypeScript starter repository.

## Project setup

```bash
$ yarn install
```

## Compile and run the project

```bash
# development
$ yarn run start

# watch mode
$ yarn run start:dev

# production mode
$ yarn run start:prod
```

## Run tests

```bash
# unit tests
$ yarn run test

# e2e tests
$ yarn run test:e2e

# test coverage
$ yarn run test:cov
```

## Deployment

When you're ready to deploy your NestJS application to production, there are some key steps you can take to ensure it runs as efficiently as possible. Check out the [deployment documentation](https://docs.nestjs.com/deployment) for more information.

If you are looking for a cloud-based platform to deploy your NestJS application, check out [Mau](https://mau.nestjs.com), our official platform for deploying NestJS applications on AWS. Mau makes deployment straightforward and fast, requiring just a few simple steps:

```bash
$ yarn install -g @nestjs/mau
$ mau deploy
```

With Mau, you can deploy your application in just a few clicks, allowing you to focus on building features rather than managing infrastructure.

## Resources

Check out a few resources that may come in handy when working with NestJS:

- Visit the [NestJS Documentation](https://docs.nestjs.com) to learn more about the framework.
- For questions and support, please visit our [Discord channel](https://discord.gg/G7Qnnhy).
- To dive deeper and get more hands-on experience, check out our official video [courses](https://courses.nestjs.com/).
- Deploy your application to AWS with the help of [NestJS Mau](https://mau.nestjs.com) in just a few clicks.
- Visualize your application graph and interact with the NestJS application in real-time using [NestJS Devtools](https://devtools.nestjs.com).
- Need help with your project (part-time to full-time)? Check out our official [enterprise support](https://enterprise.nestjs.com).
- To stay in the loop and get updates, follow us on [X](https://x.com/nestframework) and [LinkedIn](https://linkedin.com/company/nestjs).
- Looking for a job, or have a job to offer? Check out our official [Jobs board](https://jobs.nestjs.com).

## Support

Nest is an MIT-licensed open source project. It can grow thanks to the sponsors and support by the amazing backers. If you'd like to join them, please [read more here](https://docs.nestjs.com/support).

## Stay in touch

- Author - [Kamil Myśliwiec](https://twitter.com/kammysliwiec)
- Website - [https://nestjs.com](https://nestjs.com/)
- Twitter - [@nestframework](https://twitter.com/nestframework)

## License

Nest is [MIT licensed](https://github.com/nestjs/nest/blob/master/LICENSE).
