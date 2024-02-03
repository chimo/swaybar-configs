# weather

Gets weather conditions from a provided endpoint.

Sends a GET request to $WEATHER_ENDPOINT/?lon=<longitute>&lat=<latitude>

Expects a JSON response like:

```
{
    "condition": "Cloudy",
    "humidity": "45",
    "temperature": "23"
}
```

Tested with: https://srht.chromic.org/~chimo/weather/

## Usage

`weather.sh -75.695,45.424722`

## Configs

See "env.example" for instructions.

