Deno.serve(async (req: Request) => {
  const url = new URL(req.url);
  const { pathname } = url;

  const path_parts = pathname.split("/");
  const function_name = path_parts[1];

  if (!function_name || function_name === "") {
    return new Response("ok");
  }

  const servicePath = `/home/deno/functions/${function_name}`;

  const createWorker = async () => {
    const memoryLimitMb = 150;
    const workerTimeoutMs = 5 * 60 * 1000;
    const noModuleCache = false;
    const envVarsObj = Deno.env.toObject();
    const envVars = Object.keys(envVarsObj).map((k) => [k, envVarsObj[k]]);

    return await EdgeRuntime.userWorkers.create({
      servicePath,
      memoryLimitMb,
      workerTimeoutMs,
      noModuleCache,
      envVars,
      forceCreate: false,
    });
  };

  const callWorker = async () => {
    try {
      const worker = await createWorker();
      return await worker.fetch(req);
    } catch (e) {
      console.error(e);
      const error = { msg: e.toString() };
      return new Response(JSON.stringify(error), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }
  };

  return callWorker();
});
